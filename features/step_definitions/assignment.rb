# frozen_string_literal: true

When(/^I go to (.*) page from the assignment sidebar$/) do |name|
  sleep 1
  within('#assignment-sidebar') { click_link name }
  expect(page).to have_h2(name)
end
