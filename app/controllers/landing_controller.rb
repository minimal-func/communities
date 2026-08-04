class LandingController < ApplicationController
  def index
    redirect_to communities_path if current_member
  end
end
