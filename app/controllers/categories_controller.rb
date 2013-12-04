class CategoriesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @category = Category.new
  end

  def index
    @categories = Category.where("id!=1")
    .order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @category = Category.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @category }
    end
  end

  def create
    @category = Category.new params[:category]

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category,
                                  notice: 'Category was successfully created.' }
        format.json { render json: @category,
                             status: :created,
                             location: @category }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @category.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Category was successfully updated.'
        format.html { redirect_to(categories_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy


    @album_playlist_items = AlbumPlaylistItem.where("category_id = ?",
                                                    params[:id])

    if  @album_playlist_items.length.zero? || params[:id]==1

      @category = Category.find(params[:id])
      @category.destroy

    else
      flash[:notice] = 'Category could not be deleted,
category is in use in some album playlist items'
    end

    respond_to do |format|
      format.html { redirect_to(categories_url) }
    end
  end
end