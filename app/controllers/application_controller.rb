class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_member

  private

  def current_member
    @current_member ||= Member.find_by(id: session[:member_id]) if session[:member_id]
  end

  def require_member
    return if current_member

    render json: { error: "Authentication required" }, status: :unauthorized
  end
end
