ActiveAdmin.setup do |config|
  config.site_title = "Communities"
  config.comments = false
  config.root_to = "dashboard#index"
  config.authentication_method = :authenticate_admin_member!
  config.current_user_method = :current_member
  config.logout_link_path = :session_path
  config.logout_link_method = :delete
end
