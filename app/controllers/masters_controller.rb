class MastersController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  def index
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    if !params[:q].nil?
      @search = Master.ransack(params[:q])
      @masters = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: 10)
      #@search.conditions.active_equals = true
      #@search.conditions.video.programme_title_keywords =
      # params[:search][:conditions][:video][:programme_title_keywords].gsub(/\'s|\'t/,"")
      #@search.conditions.episode_title_keywords = params[:search][:conditions][:episode_title_keywords].gsub
      # # (/\'s|\'t/, "")
    else
      #no search made yet
      @search = Master.ransack(params[:q])
      @masters = @search.result(distinct: true)
      .order("id DESC")
      .paginate(page: params[:page],
                per_page: 10)
      #@search.conditions.active_equals = true

    end
    @masters_count = @masters.count

    if @masters_count == 1
      redirect_to(edit_master_path(@masters.first))
    end

    session[:masters_search] = collection_to_id_array(@masters)
  end

  def new
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    @master = Master.new
    @master.video_id = params[:id]
    # @master.language_track_1 = 'Eng'
    # @master.language_track_2 = 'Eng'
    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def create

    @master = Master.new(params[:master])

    if @master.save
      respond_to do |format|
        flash[:notice] = "Successfully created master."
        format.html { redirect_to edit_cms_video_url(@master.video) }
        format.js { render layout: false }
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
        format.js { render action: 'error.js.erb',
                           layout: false }
      end
    end
  end

  def edit
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    if !params[:q].nil?
      @search = Master.ransack(params[:q])
      @masters = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: 10)
    else
      #no search made yet
      @search = Master.ransack(params[:q])
      @masters = @search.result(distinct: true)
      .order("id DESC")
      .paginate(page: params[:page],
                per_page: 10)
    end
    @masters_count = @masters.count

    if !session[:masters_search].nil?
      ids = session[:masters_search]
      id = ids.index(params[:id].to_i)
      if !id.nil?
        @next_id = ids[id+1] if (id+1 < ids.count)
        @prev_id = ids[id-1] if (id-1 >= 0)
      end
    end

    @master = Master.find(params[:id])
    respond_to do |format|
      format.js { render layout: false }
      format.html {}
    end
  end

  def update

    @master = Master.find(params[:id])

    if @master.update_attributes(params[:master])
      respond_to do |format|
        format.html {
          flash[:notice] = "Successfully updated master."
          redirect_to edit_master_url(@master.id)
        }
        format.js { render layout: false }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.js { render action: 'error.js.erb',
                           layout: false }
      end
    end
  end

  def destroy

    @master = Master.find(params[:id])

    #check if video is in any playlists
    tot_playlists =VideoMasterPlaylistItem.count(conditions: 'master_id=' + @master.id.to_s)

    debugger

    if tot_playlists.zero?
      if permitted_to? :admin_delete,
                       :masters
        @master.destroy
        flash[:notice] = "Successfully deleted master."
        @master_is_deleted = true
      end
    else
      @master.active = false
      @master.save
      flash[:notice] = "Successfully deleted master."

      # flash[:notice] = 'Master could not be deleted, master is in use by playlists '
      @master_is_deleted = true
    end	
    respond_to do |format|    
      format.html { redirect_to edit_video_url(@master.video.id) } 
      format.js { render layout:  false}
    end
  end
  
  def duplicate
    @master = Master.find(params[:id])  
    @duplicated_master = Master.create(@master.attributes)
       
    respond_to do |format|
      format.html { redirect_to edit_video_url(@master.video.id) } 
      format.js { render layout:  false}
    end    
  end
  
  def restore
    @master = Master.find(params[:id])
    @master.to_delete = false
    @master.save(false)
    flash[:notice] = ' Master has been restored '
    respond_to do |format|
        format.html { redirect_to(:back) }
        format.js
    end
  end
end
