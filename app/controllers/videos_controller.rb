class VideosController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  def index
    @languages = IIM::MOVIE_LANGUAGES

    @search = Video.includes(:video_distributor, :commercial_run_time, :video_genres)
                   .ransack(params[:q])
    @videos = @search.result(distinct: true)
                     .order("videos.id DESC")
                     .paginate(page: params[:page],
                               per_page: items_per_page)

    if params[:language].present?
      @videos = @videos.with_language_track(params[:language][:track]) if params[:language][:track].present?
      @videos = @videos.with_language_subtitle(params[:language][:subtitle]) if params[:language][:subtitle].present?

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

  end

  def new
    @video_genres = VideoParentGenre.all
    @languages = IIM::MOVIE_LANGUAGES

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

#    respond_to do |format|
    if @video.save
      flash[:notice] = 'Video was successfully created.'
      redirect_to edit_video_path(@video)
    else
      render action: 'new'
    end
    #   end
  end

  def edit
    @search = Video.includes(:video_genres)
                   .ransack(params[:q])
    @videos = @search.result(distinct: true)
                     .paginate(page: params[:page],
                               per_page: items_per_page)
    @videos_count = @videos.count

    @languages = IIM::MOVIE_LANGUAGES

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