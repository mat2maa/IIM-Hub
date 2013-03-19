class UsersController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  def index
    @search = User.ransack(params[:q])

    @users = @search.result(distinct: true)
    .paginate(page: params[:page],
              per_page: 10)
    @users_count = @users.count
  end

  def new
    @user = User.new
  end

  def create
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
  end

  def update

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
