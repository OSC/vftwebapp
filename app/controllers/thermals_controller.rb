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
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Thermal was successfully submitted.' }
        format.json { head :no_content }
      else
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Thermal failed to be submitted: #{@thermal.errors.to_a}" }
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
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Thermal was successfully stopped.' }
        format.json { head :no_content }
      else
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Thermal failed to be stopped: #{@thermal.errors.to_a}" }
        format.json { render json: @thermal.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /thermals/1/paraview
  def paraview
    @conn = @thermal.submit_paraview
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_thermal
      @thermal = Thermal.preload(:jobs).find(params[:id])
      @session = @thermal.parent
      @mesh = @session.parent
    end
end
