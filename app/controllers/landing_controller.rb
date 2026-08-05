class LandingController < ApplicationController
  def index
    redirect_to dashboard_path if current_member
  end
end
