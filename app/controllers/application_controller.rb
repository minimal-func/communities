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

    respond_to do |format|
      format.html { redirect_to login_path, alert: "Sign in to continue." }
      format.json { render json: { error: "Authentication required" }, status: :unauthorized }
    end
  end

  def authenticate_admin_member!
    return if current_member&.admin?

    if current_member
      render plain: "Forbidden", status: :forbidden
    else
      redirect_to login_path, alert: "Sign in as an admin to continue."
    end
  end
end
