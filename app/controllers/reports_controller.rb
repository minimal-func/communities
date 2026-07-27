class ReportsController < ApplicationController
  before_action :require_member
  before_action :require_admin, only: %i[index update]
  before_action :set_reportable, only: %i[new create]

  def index
    @reports = Report.includes(:reporter_member, :reportable).order(created_at: :desc)
  end

  def new
    @report = @reportable.reports.new
  end

  def create
    @report = @reportable.reports.new(report_params.merge(reporter_member: current_member))

    if @report.save
      redirect_path = @reportable.is_a?(Post) ? post_path(@reportable) : post_path(@reportable.post)
      respond_to do |format|
        format.html { redirect_to redirect_path, notice: "Report submitted. We'll review it shortly." }
        format.json { render json: { report: @report }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @report = Report.find(params[:id])
    @report.update!(status: params[:status], resolved_by_member: current_member, resolved_at: Time.current)

    redirect_to reports_path, notice: "Report #{@report.status}."
  end

  private

  def set_reportable
    if params[:post_id]
      @reportable = Post.find(params[:post_id])
    elsif params[:comment_id]
      @reportable = Comment.find(params[:comment_id])
    else
      raise ActiveRecord::RecordNotFound, "Unknown reportable"
    end
  end

  def require_admin
    authenticate_admin_member!
  end

  def report_params
    params.require(:report).permit(:reason)
  end
end
