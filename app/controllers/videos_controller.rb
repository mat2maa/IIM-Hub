class VideosController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  autocomplete :video, :programme_title

  def index
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    if params[:q].present?
      @original = params[:q][:programme_title_or_foreign_language_title_or_chinese_programme_title_cont_any]
      @the = params[:q][:programme_title_or_foreign_language_title_or_chinese_programme_title_cont_any][0..3].downcase if params[:q][:programme_title_or_foreign_language_title_or_chinese_programme_title_cont_any].present?
      if @the == 'the ' && params[:q][:programme_title_or_foreign_language_title_or_chinese_programme_title_cont_any].present?
        @title = params[:q][:programme_title_or_foreign_language_title_or_chinese_programme_title_cont_any][4..-1].downcase
        params[:q][:programme_title_or_foreign_language_title_or_chinese_programme_title_cont_any] = ["#{@original}", "#{@title}, the"]
      end
    end

    @search = Video.includes(:video_distributor, :commercial_run_time, :video_genres)
                   .ransack(view_context.empty_blank_params params[:q])
    @videos = @search.result(distinct: true)
                     .order("videos.id DESC")
                     .paginate(page: params[:page],
                               per_page: items_per_page.present? ? items_per_page : 100)

    if params[:language].present?
      if params[:language][:track].present?
        @language_tracks = params[:language][:track].reject { |c| c.empty? }
        @language_tracks = @language_tracks.map {|language| "language_tracks LIKE '%#{language}%'"}
        @language_tracks = @language_tracks.join(" AND ")
      end

      if params[:language][:subtitle].present?
        @language_subtitles = params[:language][:subtitle].reject { |c| c.empty? }
        @language_subtitles = @language_subtitles.map {|subtitle| "language_subtitles LIKE '%#{subtitle}%'"}
        @language_subtitles = @language_subtitles.join(" AND ")
      end

      @videos = @videos.with_language_track(@language_tracks) if params[:language][:track].present?
      @videos = @videos.with_language_subtitle(@language_subtitles) if params[:language][:subtitle].present?

      @videos = @videos.with_screeners if params[:screeners] == '1'
      @videos = @videos.with_masters if params[:masters] == '1'
    end

    @videos = params[:active] == '1' ? @videos.where(active: false) : @videos.where(active: true)

    @videos = @videos.where(to_delete: true) if params[:to_delete] == '1'

    @videos_count = @videos.count

    if @videos_count == 1
      redirect_to(edit_video_path(@videos.first))
    end

    session[:videos_search] = collection_to_id_array(@videos)
  end


  def show
    @video = Video.find(params[:id])
    @playlists = VideoPlaylistItem.where('video_id=?',
                                         params[:id])

  end

  def new
    @video_genres = VideoParentGenre.all
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    @video = Video.new
    if !params[:video_type].nil?
      @video.movie_id=params[:id]
      @video.video_type=CGI.unescape(params[:video_type])
      if @video.video_type == "Movie EPK" || @video.video_type == "Movie Master" || @video.video_type == "TV Special" || @video.video_type == "Movie Trailer"
        movie = Movie.find(@video.movie_id)

        @existing_video = Video.where("programme_title=? AND video_type=?",
                                      movie.movie_title,
                                      @video.video_type).find(:first)

        if @existing_video.present?
          redirect_to edit_video_path(@existing_video)
        end

        @video.programme_title = movie.movie_title
        @video.chinese_programme_title = movie.chinese_movie_title
        @video.foreign_language_title = movie.foreign_language_title
        @video.video_distributor = movie.movie_distributor
        @video.production_studio = movie.production_studio
        @video.laboratory_id = movie.laboratory_id
        @video.language_tracks = movie.language_tracks
        @video.language_subtitles = movie.language_subtitles
        @video.synopsis = movie.synopsis
        @video.chinese_synopsis = movie.chinese_synopsis
      else
        @video.language_tracks = ["En"]
      end
    else
      @video.language_tracks = ["En"]
    end
    @video.production_year = Date.today.year

    if @video.video_type == "Movie Master"
      #@video.screeners.build
      @video.masters.build
    end

    @master = Master.where("location IS NOT NULL").order("location DESC").limit(1)
    if !@master.nil?
      @master_location = @master[0]['location'] + 1
    else
      @master_location = 0
    end
  end

  def create

    @video = Video.new(params[:video])
    @video_genres = VideoParentGenre.all

    @video.programme_title = @video.programme_title.upcase
    @video.foreign_language_title = @video.foreign_language_title.upcase if !@video.foreign_language_title.nil?

    # if production studio is empty, set it to the same as movie distributor supplier
    if @video.production_studio_id.nil?
      count_suppliers = SupplierCategory.joins(:suppliers)
      .where("supplier_id = ? and supplier_categories.name = ? ",
             @video.video_distributor_id,
             "Production Studios")
      .count('supplier_id')
      @video.production_studio_id = @video.video_distributor_id if !count_suppliers.zero?
    end

    if @video.laboratory_id.nil?
      count_suppliers = SupplierCategory.joins(:suppliers)
      .where("supplier_id = ? and supplier_categories.name = ? ",
             @video.video_distributor_id,
             "Laboratories")
      .count('supplier_id')
      @video.laboratory_id = @video.video_distributor_id if !count_suppliers.zero?
    end

    respond_to do |format|
      if @video.save
        flash[:notice] = 'Video was successfully created.'
        format.html { redirect_to edit_video_path(@video) }
      else
        format.html { render action: "new" }
        format.json { render json: @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  #def create_from_movie
  #
  #  @movie = Movie.find(params[:id])
  #  @video = Video.new()
  #
  #  #  @video.id = AUTO
  #  @video.programme_title = @movie.movie_title.upcase if @movie.movie_title.present?
  #  @video.foreign_language_title = @movie.foreign_language_title.upcase if @movie.foreign_language_title.present?
  #  @video.video_type = 'Movie Master'
  #
  #  @video.video_distributor_id = @movie.movie_distributor_id if @movie.movie_distributor_id.present?
  #  @video.production_studio_id = @movie.production_studio_id.present? ? @movie.production_studio_id : @movie.movie_distributor_id
  #  @video.laboratory_id = @movie.laboratory_id.present? ? @movie.laboratory_id : @movie.movie_distributor_id
  #
  #  @video.production_year = @movie.theatrical_release_year if @movie.theatrical_release_year.present?
  #  #  @video.episodes_available = nil
  #  @video.synopsis = @movie.synopsis if @movie.synopsis.present?
  #  #  @video.trailer_url = nil
  #  #  @video.created_at = AUTO
  #  #  @video.updated_at = AUTO
  #  #  @video.movie_id = nil
  #  #  @video.poster_file_name = nil
  #  #  @video.poster_content_type = nil
  #  #  @video.poster_file_size = nil
  #  #  @video.poster_updated_at = nil
  #  @video.to_delete = false
  #  #  @video.commercial_run_time_id = nil
  #  @video.on_going_series = false
  #  @video.remarks = ''
  #  #  @video.masters_count = nil
  #  #  @video.screeners_count = nil
  #  #  @video.in_playlists = nil
  #  @video.language_tracks = @movie.language_tracks if @movie.language_tracks.present?
  #  @video.language_subtitles = @movie.language_subtitles if @movie.language_subtitles.present?
  #  @video.active = true
  #  @video.chinese_programme_title = @movie.chinese_movie_title if @movie.chinese_movie_title.present?
  #  @video.chinese_synopsis = @movie.chinese_synopsis if @movie.chinese_synopsis.present?
  #
  #  if @video.save
  #    flash[:notice] = 'Video was successfully created.'
  #    redirect_to edit_video_path(@video)
  #  else
  #    flash[:notice] = 'There was an problem creating the video. Please try again.'
  #  end
  #end

  def edit
    @search = Video.includes(:video_genres)
    .ransack(view_context.empty_blank_params params[:q])
    @videos = @search.result(distinct: true)
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    @videos_count = @videos.count

    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    @video = Video.find(params[:id])
    @video_genres = VideoParentGenre.all
    if !session[:videos_search].nil?
      ids = session[:videos_search]
      id = ids.index(params[:id].to_i)
      if !id.nil?
        @next_id = ids[id+1] if (id+1 < ids.count)
        @prev_id = ids[id-1] if (id-1 >= 0)
      end
    end

    master = Master.where("location IS NOT NULL").order("location DESC").limit(1)

    if !master.nil?
      @master_location = master[0]['location'] + 1
    else
      @master_location = 0
    end

  end

  def update
    @video_genres = VideoParentGenre.all

    @video = Video.find(params[:id])
    params[:video][:programme_title] = params[:video][:programme_title].upcase
    params[:video][:foreign_language_title] = params[:video][:foreign_language_title].upcase if !params[:video][:foreign_language_title].nil?

    if @video.update_attributes(params[:video])
      flash[:notice] = "Successfully updated video."
      redirect_to edit_video_path(@video)
    else
      render action: 'edit'
    end
  end

  def destroy

    @video = Video.find(params[:id])

    #check if video is in any playlists
    tot_playlists = VideoPlaylistItem.count(conditions: 'video_id=' + @video.id.to_s)
    tot_master_playlists = VideoMasterPlaylistItem.count(conditions: ["master_id IN (?)",
                                                                      @video.masters])
    tot_screener_playlists = ScreenerPlaylistItem.count(conditions: ["screener_id IN (?)",
                                                                     @video.screeners])


    if tot_playlists.zero? && tot_master_playlists.zero? && tot_screener_playlists.zero?
      if permitted_to? :admin_delete,
                       :videos
        @video.destroy
        flash[:notice] = "Successfully deleted video."
        @video_is_deleted = true
      else
        @video.to_delete = true
        @video.save(validate: false)
        flash[:notice] = 'Video will be deleted when approved by administrator'
        @video_is_deleted = false
      end
    else

      @video.active = false
      @video.save
      flash[:notice] = "Successfully deactivated video. Video is still in use by some playlists."
      @video_is_deleted = true

      # flash[:notice] = 'Video could not be deleted, video is in use by playlists '
      # @video_is_deleted = false

    end

    respond_to do |format|
      format.html { redirect_to(videos_url) }
      format.js
    end

  end

  def restore
    @video = Video.find(params[:id])
    @video.to_delete = false
    @video.save(validate: false)
    flash.now[:notice] = ' Video has been restored '
    respond_to do |format|
      format.html { redirect_to(:back) }
      format.js
    end
  end

end