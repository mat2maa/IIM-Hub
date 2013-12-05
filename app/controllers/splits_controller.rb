class SplitsController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @split = Split.new
  end

  def index
    @splits = Split.order("duration")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @split = Split.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @split }
    end
  end

  def create
    @split = Split.new params[:split]
    @split.more_than = (params[:more_than_min].to_i * 60 *1000) + (params[:more_than_sec].to_i * 1000)
    @split.less_than = (params[:less_than_min].to_i * 60 *1000) + (params[:less_than_sec].to_i * 1000)

    respond_to do |format|
      if @split.save
        format.html { redirect_to @split,
                                  notice: 'Split was successfully created.' }
        format.json { render json: @split,
                             status: :created,
                             location: @split }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @split.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @split = Split.find(params[:id])

    respond_to do |format|
      if @split.update_attributes(params[:split])
        @split.more_than = (params[:more_than_min].to_i * 60 *1000) + (params[:more_than_sec].to_i * 1000)
        @split.less_than = (params[:less_than_min].to_i * 60 *1000) + (params[:less_than_sec].to_i * 1000)
        @split.save
        flash[:notice] = 'Split was successfully updated.'
        format.html { redirect_to(splits_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    @split = Split.find(params[:id])
    @split.destroy

    respond_to do |format|
      format.html { redirect_to(splits_url) }
    end
  end
end