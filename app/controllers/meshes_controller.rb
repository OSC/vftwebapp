class MeshesController < ApplicationController
  before_action :set_mesh, only: [:show, :edit, :update, :destroy]

  # GET /meshes
  # GET /meshes.json
  def index
    @meshes = Mesh.preload(:sessions)

    respond_to do |format|
      format.html
      format.json {render json: @meshes}
    end
  end

  # GET /meshes/1.json
  def show
    render json: @mesh
  end

  # POST /meshes.json
  def create
    @mesh = Mesh.new(mesh_params)

    if @mesh.save
      render json: @mesh, status: :created, location: @mesh
    else
      render json: {errors: @mesh.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /meshes/1.json
  def update
    if @mesh.update(mesh_params)
      render json: @mesh, status: :ok, location: @mesh
    else
      render json: {errors: @mesh.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /meshes/1.json
  def destroy
    if @mesh.destroy
      head :no_content
    else
      render json: {errors: @mesh.errors.full_messages}, status: :internal_server_error
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mesh
      @mesh = Mesh.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def mesh_params
      params.require(:mesh).permit!
    end
end
