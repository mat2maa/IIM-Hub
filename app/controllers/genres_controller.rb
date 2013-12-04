class GenresController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @genre = Genre.new
  end

  def index
    @genres = Genre.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @genre = Genre.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @genre }
    end
  end

  def create
    @genre = Genre.new params[:genre]

    respond_to do |format|
      if @genre.save
        format.html { redirect_to @genre,
                                  notice: 'Genre was successfully created.' }
        format.json { render json: @genre,
                             status: :created,
                             location: @genre }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @genre.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @genre = Genre.find(params[:id])

    respond_to do |format|
      if @genre.update_attributes(params[:genre])
        @albums = Album.where("genre like '%#{@genre.name}%'")
        @albums.each do |album|
          album.genre = get_genres(album.genres)
        end

        flash[:notice] = 'Genre was successfully updated.'
        format.html { redirect_to(genres_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def get_genres genres
    s = ""
    i = 1
    genres.each do |g|
      if i == 1
        s = g.name
      else
        s = s + ",
" + g.name
      end
      i += 1
    end

    s
  end

  def destroy

    id = params[:id]

    @genre = Genre.find(id)

    if @genre.albums.count == 0 && @genre.tracks.count == 0
      @genre.destroy
    else
      flash[:notice] = 'Genre could not be deleted, genre is in use in some albums or tracks'
    end

    respond_to do |format|
      format.html { redirect_to(genres_url) }
    end
  end
end