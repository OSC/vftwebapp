class SessionsController < ApplicationController
  before_action :set_session, only: [:show, :edit, :update, :destroy, :submit, :stop, :copy]
  before_action :set_mesh, only: [:index, :new, :create]

  # GET /sessions
  # GET /sessions.json
  def index
    if params[:session_list]
      if params[:session_ids]
        @sessions = @mesh.sessions.preload(:jobs, thermal: [:jobs, structural: [:jobs]]).find(params[:session_ids])
      else
        @sessions = []
      end
    else
      @sessions = @mesh.sessions.preload(:jobs, thermal: [:jobs, structural: [:jobs]])
    end
    @sessions.map! {|s| ViewModel.for_session(s, view_context) }
  end

  # GET /sessions/1
  # GET /sessions/1.json
  def show
    @session = ViewModel.for_session(@session, view_context)
  end

  # GET /sessions/new
  def new
    @session = @mesh.sessions.build
  end

  # GET /sessions/1/edit
  def edit
  end

  # POST /sessions
  # POST /sessions.json
  def create
    @session = @mesh.sessions.build(session_params)
    @session = ViewModel.for_session(@session, view_context)

    respond_to do |format|
      if @session.save
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Session was successfully created.' }
        format.js   { render :show }
        format.json { render :show, status: :created, location: @session }
      else
        format.html { render :new }
        format.json { render json: @session.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sessions/1
  # PATCH/PUT /sessions/1.json
  def update
    respond_to do |format|
      if @session.update(session_params)
        format.html { redirect_to @session, notice: 'Session was successfully updated.' }
        format.json { render :show, status: :ok, location: @session }
      else
        format.html { render :edit }
        format.json { render json: @session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sessions/1
  # DELETE /sessions/1.json
  def destroy
    respond_to do |format|
      if @session.destroy
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Session was successfully destroyed.' }
        format.js
        format.json { head :no_content }
      else
        @errors = @session.errors
        set_session
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Session failed to be destroyed: #{@session.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @session.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /sessions/1/submit
  # PUT /sessions/1/submit.json
  def submit
    respond_to do |format|
      if @session.submitted?
        @session.jobs.each {|j| j.update_status!(force: true)}
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), alert: 'Session has already been submitted.' }
        format.js   { render :show }
        format.json { head :no_content }
      elsif @session.submit
        set_session
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Session was successfully submitted.' }
        format.js   { render :show }
        format.json { head :no_content }
      else
        @errors = @session.errors
        set_session
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Session failed to be submitted: #{@session.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @session.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /sessions/1/stop
  def stop
    respond_to do |format|
      if !@session.submitted?
        format.html { redirect_to mesh_sessions_url(@mesh), alert: 'Session has not been submitted.' }
        format.json { head :no_content }
      elsif @session.stop
        set_session
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), notice: 'Session was successfully stopped.' }
        format.js   { render :show }
        format.json { head :no_content }
      else
        @errors = @session.errors
        set_session
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Session failed to be stopped: #{@session.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @session.errors, status: :internal_server_error }
      end
    end
  end

  # PUT /sessions/1/copy
  def copy
    @session = @session.copy

    respond_to do |format|
      if @session.save
        @session = ViewModel.for_session(@session, view_context)
        format.html { redirect_to @session, notice: 'Session was successfully copied.' }
        format.js   { render :show }
        format.json { render :show, status: :created, location: @session }
      else
        @errors = @session.errors
        @session = nil
        format.html { redirect_to mesh_sessions_url(@mesh), alert: "Session failed to be copied: #{@session.errors.to_a}" }
        format.js   { render 'sessions/error' }
        format.json { render json: @session.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_session
      @session = Session.find(params[:id])
      @session.resx = params[:resx] if params[:resx]
      @session.resy = params[:resy] if params[:resy]
      @mesh = @session.parent
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_mesh
      @mesh = Mesh.find(params[:mesh_id])
    end

    # Only allow a trusted parameter "white list" through.
    def session_params
      params.require(:session).permit!
    end
end
