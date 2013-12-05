class PublishersController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @publisher = Publisher.new
  end

  def index
    @publishers = Publisher.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @publisher = Publisher.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @publisher = Publisher.new params[:publisher]

    respond_to do |format|
      if @publisher.save
        format.html { redirect_to @publisher,
                                  notice: 'Publisher was successfully created.' }
        format.json { render json: @publisher,
                             status: :created,
                             location: @publisher }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @publisher.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @publisher = Publisher.find(params[:id])

    respond_to do |format|
      if @publisher.update_attributes(params[:publisher])
        flash[:notice] = 'Publisher was successfully updated.'
        format.html { redirect_to(publishers_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy


    @albums = Album.where("publisher_id = ?",
                          params[:id])

    if  @albums.length.zero?

      @publisher = Publisher.find(params[:id])
      @publisher.destroy

    else
      flash[:notice] = 'Publisher could not be deleted,
publisher is in use in some albums or tracks'
    end

    respond_to do |format|
      format.html { redirect_to(publishers_url) }
    end
  end
end