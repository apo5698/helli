class AssignmentsController < AssignmentsViewController
  #  GET /courses/:course_id/assignments
  def index
    @title = controller_name.classify.pluralize
    @assignments = @course.assignments
    return unless flash[:modal_error]

    @assignment ||= Assignment.new
    @assignment.assign_attributes(assignment_params)
  end

  #  GET /courses/:course_id/assignments/new
  def new
    @assignment = Assignment.new
  end

  #  POST /courses/:course_id/assignments
  def create
    Assignment.create!(assignment_params.merge(course_id: params.require(:course_id)))

    flash.notice = "Assignment '#{assignment_params[:name]}' created."
    redirect_back fallback_location: { action: :index }
  end

  #  GET /courses/:course_id/assignments/:id
  def show
    @title = @assignment.name
    @program = Program.new
  end

  #  PUT /courses/:course_id/assignments/:id
  def update
    assignment = Assignment.find(params.require(:id))
    assignment.update!(assignment_params.merge(course_id: params.require(:course_id)))

    flash.notice = "Assignment '#{assignment.name}' updated."
    redirect_to action: index, assignment: assignment_params, id: assignment.id
  end

  #  DELETE /courses/:course_id/assignments/:id
  def destroy
    assignment = Assignment.find(params.require(:id))
    name = assignment.name
    assignment.destroy

    flash.notice = "Assignment '#{name}' deleted."
    redirect_back fallback_location: { action: :index }
  end

  #  PUT /courses/:course_id/assignments/:id/input_files
  def input_file_add
    file = params.require(:file)
    @assignment.input_files.attach(file)

    flash.notice = "Input file '#{file.original_filename}' added."
    redirect_back fallback_location: { action: :show }
  end

  #  DELETE /courses/:course_id/assignments/:id/input_files?name=#{name}
  def input_file_delete
    filename = params.require(:name)
    @assignment.input_files.delete_by_filename(filename)

    flash.notice = "Input file '#{filename}' deleted."
    redirect_back fallback_location: { action: :show }
  end

  def copy
    @other_courses = Course.of(current_user.id).reject { |course| course == @course }
    @other_courses |= []
  end

  def copy_to
    selected_courses.each do |course_id|
      @assignment.dup_to(course_id)
    end

    flash.notice = "Assignment #{@assignment} has been successfully copied over."
    redirect_to action: :index
  end

  private

  def assignment_params
    params.require(:assignment).permit(:name, :category, :description)
  end

  def selected_courses
    params.require(:courses).permit!.keep_if { |_, v| v == '1' }.keys
  end
end
