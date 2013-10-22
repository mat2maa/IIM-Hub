class MoviePlaylistTypesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @movie_playlist_type = MoviePlaylistType.new
  end

  def index
    @movie_playlist_types = MoviePlaylistType.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @movie_playlist_type = MoviePlaylistType.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @movie_playlist_type = MoviePlaylistType.new(params[:movie_playlist_type])

    respond_to do |format|
      if @movie_playlist_type.save
        format.html { redirect_to @movie_playlist_type,
                                  notice: 'Movie type was successfully created.' }
        format.json { render json: @movie_playlist_type,
                             status: :created,
                             location: @movie_playlist_type }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @movie_playlist_type.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @movie_playlist_type = MoviePlaylistType.find(params[:id])

    respond_to do |format|
      if @movie_playlist_type.update_attributes(params[:movie_playlist_type])
        flash[:notice] = 'MoviePlaylistType was successfully updated.'
        format.html { redirect_to(movie_playlist_types_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]

    @movie_playlist_type = MoviePlaylistType.find(id)

    @movie_playlists = @movie_playlist_type.movie_playlists

    if @movie_playlists.length.zero?
      @movie_playlist_type.destroy
    else
      flash[:notice] = 'MoviePlaylistType could not be deleted, movie_playlist_type is in use in some tracks'
    end

    respond_to do |format|
      format.html { redirect_to movie_playlist_types_url }
    end
  end
end
