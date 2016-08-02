class SessionsController < ApplicationController
  before_action :update_jobs

  # GET /sessions
  # GET /sessions.json
  def index
    @mesh = Mesh.find(params[:mesh_id])
    @sessions = @mesh.sessions.preload(:session_job)
    # @sessions = @mesh.sessions.where("created_at >= ?", Time.zone.now.beginning_of_day)

    respond_to do |format|
      format.html
      format.json {render json: @sessions}
    end
  end

  # GET /sessions/1
  # GET /sessions/1.json
  def show
    @session = Session.find(params[:id])

    render json: @session
  end

  # GET /sessions/1/edit
  def edit
    @session = Session.find(params[:id])
  end

  # POST /sessions.json
  def create
    @mesh = Mesh.find(params[:mesh_id])
    @session = @mesh.sessions.build(session_params)

    if @session.save
      render json: @session, status: :created, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sessions/1.json
  def update
    @session = Session.find(params[:id])

    if @session.update(session_params)
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /sessions/1/submit.json
  def submit
    @session = Session.find(params[:id])

    if @session.not_submitted? && @session.update(session_params) && @session.submit!
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /sessions/1/validate.json
  def validate
    @session = Session.find(params[:id])

    if @session.failed? && @session.validate!
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /sessions/1/back.json
  def back
    @session = Session.find(params[:id])

    if !@session.active? && !@session.vftsolid? && @session.back!
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /sessions/1/skip.json
  def skip
    @session = Session.find(params[:id])

    if @session.not_submitted? && !@session.complete? && @session.skip!
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /sessions/1/stop.json
  def stop
    @session = Session.find(params[:id])

    if @session.active? && @session.stop!
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /sessions/1.json
  def destroy
    @session = Session.find(params[:id])

    if @session.destroy
      head :no_content
    else
      render json: {errors: @session.errors.full_messages}, status: :internal_server_error
    end
  end

  # GET /sessions/1/thermal_paraview.json
  def thermal_paraview
    @session = Session.find(params[:id])

    if @session.thermal_paraview? && link = @session.thermal_paraview
      render json: {link: link}
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # GET /sessions/1/structural_paraview.json
  def structural_paraview
    @session = Session.find(params[:id])

    if @session.structural_paraview? && link = @session.structural_paraview
      render json: {link: link}
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  private
    # Only allow a trusted parameter "white list" through.
    def session_params
      params.require(:session).permit! if params[:session]
    end

    # Update the status of all the jobs
    def update_jobs
      SessionJob.all.to_a.each(&:update_status!)
    end
end
