require "test_helper"

class LoginPageTest < ActionDispatch::IntegrationTest
  test "renders login page" do
    get login_path

    assert_response :success
    assert_select "h1", "Member Login"
    assert_select "form[data-controller='wallet-login']"
    assert_select "a.support-link[href='https://buymeacoffee.com/ildar.safin'][target='_blank'][rel='noopener']", "Buy me a coffee"
  end

  test "root renders the landing page" do
    get root_path

    assert_response :success
    assert_select "h1", "Build a culture of enough."
    assert_select "a[href='#{login_path}']", "Enter your community"
    assert_select "a.support-link[href='https://buymeacoffee.com/ildar.safin'][target='_blank'][rel='noopener']", "Buy me a coffee"
  end
end
