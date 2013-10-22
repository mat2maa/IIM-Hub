class MovieGenresController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @movie_genre = MovieGenre.new
  end

  def index
    @movie_genres = MovieGenre.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @movie_genre = MovieGenre.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @movie_genre = MovieGenre.new params[:movie_genre]

    respond_to do |format|
      if @movie_genre.save
        format.html { redirect_to @movie_genre,
                                  notice: 'Movie Genre was successfully created.' }
        format.json { render json: @movie_genre,
                             status: :created,
                             location: @movie_genre }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @movie_genre.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @movie_genre = MovieGenre.find(params[:id])

    respond_to do |format|
      if @movie_genre.update_attributes(params[:movie_genre])
        #Movie.update_all(["movie_genre_cache=?",@movie_genre.name],["movie_genre_id=?",@movie_genre.id] )
        flash[:notice] = 'MovieGenre was successfully updated.'
        format.html { redirect_to(movie_genres_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]

    @movie_genre = MovieGenre.find(id)

    @movies = @movie_genre.movies

    if @movies.length.zero?
      @movie_genre.destroy
    else
      flash[:notice] = 'MovieGenre could not be deleted, movie_genre is in use in some tracks'
    end

    respond_to do |format|
      format.html { redirect_to(movie_genres_url) }
    end
  end
end