class MovieTypesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @movie_type = MovieType.new
  end

  def index
    @movie_types = MovieType.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @movie_type = MovieType.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @movie_type = MovieType.new(params[:movie_type])

    respond_to do |format|
      if @movie_type.save
        format.html { redirect_to @movie_type,
                                  notice: 'Movie type was successfully created.' }
        format.json { render json: @movie_type,
                             status: :created,
                             location: @movie_type }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @movie_type.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @movie_type = MovieType.find(params[:id])

    respond_to do |format|
      if @movie_type.update_attributes(params[:movie_type])
        flash[:notice] = 'MovieType was successfully updated.'
        format.html { redirect_to(movie_types_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]

    @movie_type = MovieType.find(id)

    @movies = @movie_type.movies

    if @movies.length.zero?
      @movie_type.destroy
    else
      flash[:notice] = 'MovieType could not be deleted, movie_type is in use in some tracks'
    end

    respond_to do |format|
      format.html { redirect_to movie_types_url }
    end
  end
end
