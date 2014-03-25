class UsersController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  def index
    @search = User.ransack(view_context.empty_blank_params params[:q])

    @users = @search.result(distinct: true).order('id ASC')
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    @users_count = @users.count
  end

  def new
    @user = User.new
  end

  def create
    if params[:user][:roles]
      roles = params[:user][:roles].reject! { |c| c.empty? }
      params[:user][:roles] = roles.map { |r| Role.find(r).name }
    end

    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default users_url
    else
      render action: :new
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])

    @user_roles = @user.roles.collect { |r| Role.where("name = ?", r) }.flatten
    @roles_list = []
    @user_roles.each do |r|
      @roles_list << r.id
    end
  end

  def update
    if params[:user][:roles]
      roles = params[:user][:roles].reject! { |c| c.empty? }
      params[:user][:roles] = roles.map { |r| Role.find(r).name }
    end

    @user = User.find(params[:id])

    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to users_path
    else
      render action: :edit_own_password
    end
  end

  def edit_own_password
    @user = current_user
  end

  def update_own_password
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = "Password updated!"
      redirect_to root_path
    else
      render action: :edit
    end
  end

  def enable
    @user = User.find(params[:id])
    @user.enabled = true
    @user.save
    redirect_to :back
  end

  def disable
    @user = User.find(params[:id])
    @user.enabled = false
    @user.save
    redirect_to :back
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

end