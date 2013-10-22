class RightsController < ApplicationController
  before_filter :require_user
  filter_access_to :all
  before_filter only: [:index, :new] do
    @right = Right.new
  end

  def index
    @search = Right.ransack(view_context.empty_blank_params params[:q])
    @rights = @search.result(distinct: true)
    .paginate(page: params[:page],
              per_page: items_per_page)
    @rights_count = @rights.count
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @right }
    end
  end

  def create
    @right = Right.new params[:right]

    respond_to do |format|
      if @right.save
        format.html { redirect_to rights_url,
                                  notice: 'Right was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def edit
    @right = Right.find(params[:id])
  end

  def update
    @right = Right.find(params[:id]) # makes our views "cleaner" and more consistent
    if @right.update_attributes(params[:right])
      flash[:notice] = "Right updated!"
      redirect_to rights_path
    else
      render action: :edit
    end
  end

  def destroy
    @right = Right.find(params[:id])
    @right.destroy
    flash[:notice] = 'Right successfully destroyed.'
    redirect_to rights_path
  end
end