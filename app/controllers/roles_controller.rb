class RolesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index, :new] do
    @role = Role.new
  end

  def index
    @search = Role.ransack(view_context.empty_blank_params params[:q])
    @roles = @search.result(distinct: true)
                    .paginate(page: params[:page],
                              per_page: items_per_page.present? ? items_per_page : 100)
    @roles_count = @roles.count
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(params[:role])
    if @role.save
      flash[:notice] = "Role created"
      redirect_back_or_default roles_url
    else
      render action: :new
    end
  end

  def show
    @role = @current_role
  end

  def edit
    @role = Role.find(params[:id])
  end

  def update
    @role = Role.find(params[:id])
    params[:role][:right_ids] ||= []

    if @role.update_attributes(params[:role])
      flash[:notice] = "Account updated!"
      redirect_to roles_path
    else
      render action: :edit
    end
  end

  def destroy
    @role = Role.find(params[:id])
    @role.destroy
    flash[:notice] = 'Role successfully destroyed.'
    redirect_to roles_path
  end

end