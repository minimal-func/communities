ActiveAdmin.setup do |config|
  config.site_title = "Communities"
  config.comments = false
  config.root_to = "dashboard#index"
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user
  config.logout_link_path = :destroy_admin_user_session_path
  config.logout_link_method = :delete
end
