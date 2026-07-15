class ImagesController < ApplicationController
  before_action :require_member

  def create
    image = current_member.images.create!(image_params)
    render json: { url: url_for(image.file) }, status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def image_params
    params.require(:image).permit(:file)
  end
end