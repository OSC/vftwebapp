class StructuralsController < ApplicationController
  before_action :set_structural, only: [:submit, :stop, :paraview]

  # PUT /structurals/1/submit
  # PUT /structurals/1/submit.json
  def submit
    respond_to do |format|
      if @structural.submitted?
        format.html { redirect_to mesh_sessions_url(@mesh), alert: 'Structural has already been submitted.' }
        format.json { head :no_content }
      elsif @structural.submit
        set_structural
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Structural was successfully submitted.' }
        format.js   { render 'sessions/show' }
        format.json { head :no_content }
      else
        @errors = @structural.errors
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Structural failed to be submitted: #{@structural.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @structural.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /structurals/1/stop
  def stop
    respond_to do |format|
      if !@structural.submitted?
        format.html { redirect_to mesh_sessions_url(@mesh), alert: 'Structural has not been submitted.' }
        format.json { head :no_content }
      elsif @structural.stop
        set_structural
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Structural was successfully stopped.' }
        format.js   { render 'sessions/show' }
        format.json { head :no_content }
      else
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Structural failed to be stopped: #{@structural.errors.to_a}" }
        format.json { render json: @structural.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /structurals/1/paraview
  def paraview
    @conn = @structural.submit_paraview
    respond_to do |format|
      format.html
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_structural
      @structural = Structural.find(params[:id])
      @structural.hours = params[:hours] if params[:hours]

      @thermal = @structural.parent
      @session = @thermal.parent
      @mesh = @session.parent
    end
end
