class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Update job status on every action
  before_action :update_job_status

  private
    def update_job_status
      # Job.active.to_a.each(&:update_status!)
    end
end
