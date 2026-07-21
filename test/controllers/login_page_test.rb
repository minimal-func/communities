require "test_helper"

class LoginPageTest < ActionDispatch::IntegrationTest
  test "renders login page" do
    get login_path

    assert_response :success
    assert_select "h1", "Member Login"
    assert_select "form[data-controller='wallet-login']"
  end

  test "root renders login page" do
    get root_path

    assert_response :success
    assert_select "h1", "Member Login"
  end
end
