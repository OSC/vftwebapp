class SessionsController < ApplicationController
  before_action :update_jobs

  # GET /sessions
  # GET /sessions.json
  def index
    @mesh = Mesh.find(params[:mesh_id])
    @sessions = @mesh.sessions.preload(:session_job)

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

    if @session.submit!
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
