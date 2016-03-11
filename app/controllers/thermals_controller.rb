class ThermalsController < ApplicationController
  before_action :set_thermal, only: [:submit, :stop, :paraview]

  # PUT /thermals/1/submit
  # PUT /thermals/1/submit.json
  def submit
    respond_to do |format|
      if @thermal.submitted?
        format.html { redirect_to mesh_sessions_url(@mesh), alert: 'Thermal has already been submitted.' }
        format.json { head :no_content }
      elsif @thermal.submit
        set_thermal
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Thermal was successfully submitted.' }
        format.js   { render 'sessions/show' }
        format.json { head :no_content }
      else
        @errors = @thermal.errors
        set_thermal
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Thermal failed to be submitted: #{@thermal.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @thermal.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /thermals/1/stop
  def stop
    respond_to do |format|
      if !@thermal.submitted?
        format.html { redirect_to mesh_sessions_url(@mesh), alert: 'Thermal has not been submitted.' }
        format.json { head :no_content }
      elsif @thermal.stop
        set_thermal
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Thermal was successfully stopped.' }
        format.js   { render 'sessions/show' }
        format.json { head :no_content }
      else
        @errors = @thermal.errors
        set_thermal
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Thermal failed to be stopped: #{@thermal.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @thermal.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /thermals/1/paraview
  def paraview
    @conn = @thermal.submit_paraview
    respond_to do |format|
      format.html
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_thermal
      @thermal = Thermal.find(params[:id])
      @thermal.hours = params[:hours] if params[:hours]
      @thermal.resx = params[:resx] if params[:resx]
      @thermal.resy = params[:resy] if params[:resy]

      @session = @thermal.parent
      @mesh = @session.parent
    end
end
