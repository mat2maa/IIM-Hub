class AlbumCategoriesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index, :new] do
    @album_category = AlbumCategory.new
  end


  # GET /album_categories
  # GET /album_categories.json
  def index
    @album_categories = AlbumCategory.order("name asc")
                                     .paginate(page: params[:page],
                                               per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @album_categories }
    end
  end

  # GET /album_categories/1
  # GET /album_categories/1.json
  def show
    @album_category = AlbumCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @album_category }
    end
  end

  # GET /album_categories/new
  # GET /album_categories/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @album_category }
    end
  end

  # GET /album_categories/1/edit
  def edit
    @album_category = AlbumCategory.find(params[:id])
  end

  # POST /album_categories
  # POST /album_categories.json
  def create
    @album_category = AlbumCategory.new(params[:album_category])

    respond_to do |format|
      if @album_category.save
        format.html { redirect_to @album_category, notice: 'Album category was successfully created.' }
        format.json { render json: @album_category, status: :created, location: @album_category }
      else
        format.html { render action: "new" }
        format.json { render json: @album_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /album_categories/1
  # PUT /album_categories/1.json
  def update
    @album_category = AlbumCategory.find(params[:id])

    respond_to do |format|
      if @album_category.update_attributes(params[:album_category])
        format.html { redirect_to @album_category, notice: 'Album category was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @album_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /album_categories/1
  # DELETE /album_categories/1.json
  def destroy
    @album_category = AlbumCategory.find(params[:id])
    @album_category.destroy

    respond_to do |format|
      format.html { redirect_to album_categories_url }
      format.json { head :no_content }
    end
  end
end
