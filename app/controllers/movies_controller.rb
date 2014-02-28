require 'rottentomatoes'
include RottenTomatoes

# setup your API key
Rotten.api_key = "snr4rshxrz9cqgpfsswebhb7"

class MoviesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  autocomplete :movie, :movie_title

  def index
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    if params[:q].present?
      @original = params[:q][:movie_title_or_foreign_language_title_or_chinese_movie_title_cont_any]
      @the = params[:q][:movie_title_or_foreign_language_title_or_chinese_movie_title_cont_any][0..3].downcase if params[:q][:movie_title_or_foreign_language_title_or_chinese_movie_title_cont_any].present?
      if @the == 'the ' && params[:q][:movie_title_or_foreign_language_title_or_chinese_movie_title_cont_any].present?
        @title = params[:q][:movie_title_or_foreign_language_title_or_chinese_movie_title_cont_any][4..-1].downcase
        params[:q][:movie_title_or_foreign_language_title_or_chinese_movie_title_cont_any] = ["#{@original}", "#{@title}, the"]
      end
    end

    @search = Movie.includes(:movie_distributor, :movie_type)
    .ransack(view_context.empty_blank_params params[:q])

    @movies = @search.result(distinct: true)
    .order("movies.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    if params[:language].present?
      if params[:language][:track].present?
        @language_tracks = params[:language][:track].reject! { |c| c.empty? }
        @language_tracks = @language_tracks.map { |language| "language_tracks LIKE '%#{language}%'" }
        @language_tracks = @language_tracks.join(" AND ")
      end

      if params[:language][:subtitle].present?
        @language_subtitles = params[:language][:subtitle].reject! { |c| c.empty? }
        @language_subtitles = @language_subtitles.map { |subtitle| "language_subtitles LIKE '%#{subtitle}%'" }
        @language_subtitles = @language_subtitles.join(" AND ")
      end

      @movies = @movies.with_language_track(@language_tracks) if params[:language][:track].present?
      @movies = @movies.with_language_subtitle(@language_subtitles) if params[:language][:subtitle].present?

      @movies = @movies.with_screener_destroyed if params[:screener][:destroyed] == '1'
      @movies = @movies.with_screener_held if params[:screener][:held] == '1'
    end

    @movies = params[:active] == '1' ? @movies.where(active: false) : @movies.where(active: true)

    @movies = @movies.where(to_delete: true) if params[:to_delete] == '1'

    @movies_count = @movies.count

    if @movies_count == 1
      redirect_to(edit_movie_path(@movies.first))
    end

    session[:movies_search] = collection_to_id_array(@movies)
  end

  def show
    @movie = Movie.find(params[:id])
    @playlists = MoviePlaylistItem.where('movie_id=?',
                                         params[:id])
    if !session[:movies_search].nil?
      ids = session[:movies_search]
      id = ids.index(params[:id].to_i)
      if !id.nil?
        @next_id = ids[id+1] if (id+1 < ids.count)
        @prev_id = ids[id-1] if (id-1 >= 0)
      end
    end
  end

  def new
    @movie = Movie.new
    @movie.theatrical_release_year = Date.today.year
    @movie.release_versions = ["Th"]
    @movie.movie_type_id = "1"
    @movie.airline_rights = "Worldwide"
    @movie.language_tracks = ["Eng"]
    @movie.screener_received_date = nil
    @movie.screener_destroyed_date = nil
    @movie.airline_release_date = nil
    @movie.personal_video_date = nil

    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }
  end

  def create
    @movie = Movie.new(params[:movie])
    @movie.movie_title = @movie.movie_title.upcase
    @movie.foreign_language_title = @movie.foreign_language_title.upcase if !@movie.foreign_language_title.nil?
    @movie.director = @movie.director.gsub(/\b\w/) { $&.upcase }
    @movie.cast = @movie.cast.gsub(/\b\w/) { $&.upcase }

#    respond_to do |format|
    if @movie.save
      flash[:notice] = 'Movie was successfully created.'
      redirect_to edit_movie_path(@movie)
    else
      render action: 'new'
    end
    #   end
  end

  def edit
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    @search = Movie.includes(:movie_distributor, :movie_type)
    .ransack(view_context.empty_blank_params params[:q])
    @movies = @search.result(distinct: true)
    .order("movies.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    @movies_count = @movies.count

    @movie = Movie.find(params[:id])

    session[:movies_search] = collection_to_id_array(@movies)
    respond_to do |format|
      format.html {}
    end
  end

  #display overlay
  def add_review_to_movie

    @original_movie = Movie.find(params[:id])

    @movies = RottenMovie.find(:title => "#{@original_movie.movie_title}")

    if @movies.kind_of?(Array)
      @movies_count = @movies.count
      if params[:index]
        @movie = @movies[params[:index].to_i]
      else
        @movie = @movies[0]
      end
    elsif @movies.kind_of?(PatchedOpenStruct)
      @movies_count = 1
      @movie = @movies
    end

    if @movies_count > 0
      @reviews_uri = URI(@movie.links.reviews + "?apikey=snr4rshxrz9cqgpfsswebhb7")
      @response = Net::HTTP.get_response(@reviews_uri)
      @reviews_json = JSON.parse(@response.body)
      @reviews_count = @reviews_json["total"]

      if @reviews_count > 0
        @reviews = @reviews_json["reviews"]
      end
    end

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def update
    @search = Movie.ransack(view_context.empty_blank_params params[:q])
    @movies = @search.result(distinct: true)
    .order("movies.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    @movies_count = @movies.count

    @movie = Movie.find(params[:id])
    params[:movie][:movie_title] = params[:movie][:movie_title].upcase
    params[:movie][:director] = params[:movie][:director].gsub(/\b\w/) { $&.upcase }
    params[:movie][:cast] = params[:movie][:cast].gsub(/\b\w/) { $&.upcase }
    params[:movie][:foreign_language_title] = params[:movie][:foreign_language_title].upcase if !params[:movie][:foreign_language_title].nil?

    #remove empty string from starts of arrays
    #params[:movie][:release_versions] = params[:movie][:release_versions].reject! { |c| c.empty? } if !params[:movie][:release_versions].nil?
    #params[:movie][:language_tracks] = params[:movie][:language_tracks].reject! { |c| c.empty? } if !params[:movie][:language_tracks].nil?
    #params[:movie][:language_subtitles] = params[:movie][:language_subtitles].reject! { |c| c.empty? } if !params[:movie][:language_subtitles].nil?
    #params[:movie][:movie_genre_ids] = params[:movie][:movie_genre_ids].reject! { |c| c.empty? } if !params[:movie][:movie_genre_ids].nil?

    if @movie.update_attributes(params[:movie])
      flash[:notice] = "Successfully updated movie."
      redirect_to edit_movie_path(@movie)
    else
      render action: 'edit'
    end
  end

  def destroy
    @movie = Movie.find(params[:id])

    #check if video is in any playlists
    tot_playlists =MoviePlaylistItem.count(conditions: 'movie_id=' + @movie.id.to_s)

    if tot_playlists.zero?
      if permitted_to? :admin_delete,
                       :movies
        @movie.destroy
        flash[:notice] = "Successfully deleted movie."
        @movie_is_deleted = true
      else
        @movie.to_delete = true
        @movie.save(validate: false)
        flash[:notice] = 'Movie will be deleted when approved by administrator'
        @movie_is_deleted = false
      end
    else
      @movie.active = false
      @movie.save
      flash[:notice] = "Successfully deactivated movie."
      @movie_is_deleted = true

      #flash[:notice] = 'Movie could not be deleted, movie is in use for by playlists '
    end

    respond_to do |format|
      format.html { redirect_to(movies_url) }
      format.js
    end
  end

  def update_date
    respond_to do |format|
      format.js
    end
  end

  def restore
    @movie = Movie.find(params[:id])
    @movie.to_delete = false
    @movie.save(validate: false)
    flash[:notice] = 'Movie has been restored '
    respond_to do |format|
      format.html { redirect_to(:back) }
      format.js
    end
  end

end