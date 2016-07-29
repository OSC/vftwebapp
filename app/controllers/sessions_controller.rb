class SessionsController < ApplicationController
  before_action :set_session, only: [:show, :edit, :update, :destroy]

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
    if @session.update(session_params)
      render json: @session, status: :ok, location: @session
    else
      render json: {errors: @session.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /sessions/1.json
  def destroy
    if @session.destroy
      head :no_content
    else
      render json: {errors: @session.errors.full_messages}, status: :internal_server_error
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_session
      @session = Session.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def session_params
      params.require(:session).permit! if params[:session]
    end
end
