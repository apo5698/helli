# frozen_string_literal: true

# Grade items are generated from a rubric item, and associated with a participant.
class GradeItem < ApplicationRecord
  attr_accessor :content

  ################
  # Enumerations #
  ################

  enum status: {
    inactive: 'Inactive',
    success: 'Success',
    resolved: 'Resolved',
    unresolved: 'Unresolved',
    error: 'Error',
    no_submission: 'No submission'
  }

  ################
  # Associations #
  ################

  belongs_to :participant
  belongs_to :rubric_item, class_name: 'Rubrics::Item::Base'

  ###############
  # Validations #
  ###############

  # Negative grade does not make sense.
  validates :point, numericality: { greater_than_or_equal_to: 0 }

  #############
  # Callbacks #
  #############

  # Set default status if not specified.
  after_initialize { inactive! if status.nil? }

  # Ask participant to fetch latest grades and feedbacks
  after_save { participant.fetch }

  ###############
  # Delegations #
  ###############

  delegate :<=>, :name, to: :participant
  delegate :to_s, :filename, :maximum_points, to: :rubric_item

  def feedback=(feedback)
    super(Helli::SeparatedString.new(feedback).to_s)
  end

  # Resets the grade item the initial state (empty).
  def reset
    update!({ status: :inactive, stdout: '', stderr: '', error: 0, point: 0, feedback: '' })
  end

  # Returns the attachment with the same filename within its participant's submissions.
  #
  # @return [ActiveStorage::Attachment, nil]
  def attachment
    participant.attachment(rubric_item.filename)
  end

  # Accepts a series of options and then invokes #run per its rubric type.
  #
  # @param [Hash, ActionController::Parameters] options
  # @return [GradeItem] self
  def run(options)
    if rubric_item.type == 'Rubrics::Item::Zybooks'
      path = participant.zybooks_redis_key
    else
      # No submission per Moodle grade worksheet.
      if participant.no_submission?
        update!(attributes_preset_for(:no_submission))
        return self
      end

      if attachment.nil?
        update!(attributes_preset_for(:no_matched_attachment))
        return self
      end

      # Downloading strategy:
      #   1. Download files to a temporary directory
      #   2. Keep them for a period of time (default 4 hours)
      #   3. Delete using cron jobs (sidekiq)
      path = Attachment.download_one(attachment, "participant-#{participant.id}")
    end

    # Assigns attributes before grading
    self.status = :success
    self.point = 0

    captures, error = rubric_item.run(path, options)

    if rubric_item.type == 'Rubrics::Item::Zybooks'
      self.point = captures[0]
      self.feedback = captures[1]
    else
      self.stdout = captures.stdout
      self.stderr = captures.stderr
      self.exitstatus = captures.exitstatus
      self.error = error

      @content = File.read(path)
    end

    new_feedback = Helli::SeparatedString.new

    rubric_item.criteria.each do |c|
      c.grade_item = self
      new_feedback << c.validate
    end

    self.feedback = new_feedback

    # Grade cannot be negative
    self.point = 0 if point.negative?

    save!
    self
  rescue Encoding::UndefinedConversionError => e
    unresolved!
    self.feedback = "Failed to grade during transcoding - #{e}"
    save!
    self
  end

  # An error message indicating that a manual resolution is needed.
  def resolve_manually(msg)
    "#{msg}. Please resolve manually."
  end

  # @param [Symbol] type
  # @return [Hash]
  def attributes_preset_for(type)
    case type
    when :no_submission
      { status: :no_submission, error: ['No submission'] }
    when :no_matched_attachment
      { status: :unresolved, error: [resolve_manually('No matched filename')] }
    else
      raise "Unknown attributes type: #{type}"
    end
  end
end
