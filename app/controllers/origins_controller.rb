class OriginsController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @origin = Origin.new
  end

  def index
    @origins = Origin.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @origin = Origin.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @origin = Origin.new params[:origin]

    respond_to do |format|
      if @origin.save
        format.html { redirect_to @origin,
                                  notice: 'Origin was successfully created.' }
        format.json { render json: @origin,
                             status: :created,
                             location: @origin }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @origin.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @origin = Origin.find(params[:id])

    respond_to do |format|
      if @origin.update_attributes(params[:origin])
        flash[:notice] = 'Origin was successfully updated.'
        format.html { redirect_to(origins_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy


    @tracks = Track.where("origin_id = ?",
                          params[:id])

    if  @tracks.length.zero?

      @origin = Origin.find(params[:id])
      @origin.destroy

    else
      flash[:notice] = 'Origin could not be deleted,
origin is in use in some tracks'
    end

    respond_to do |format|
      format.html { redirect_to(origins_url) }
    end
  end
end