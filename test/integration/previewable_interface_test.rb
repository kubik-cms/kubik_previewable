# frozen_string_literal: true

require "test_helper"

class BlogTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    visit "/admin/login"
    sign_in admin_users(:admin)
    assert_equal(page.status_code, 200)
  end

  test "shows blog posts" do
    visit admin_examples_path
    within(".index_as_table") do
      click_on "Edit"
    end
    click_on "Preview"
    page.assert_all_of_selectors(:css, "tr.row-title_tag", visible: true)
    assert_includes(page.first("tr.row-title_tag").text, "Test title tag")
  end
end
