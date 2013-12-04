class ScreenersController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  def index
    @languages = MasterLanguage.order("name")
                               .collect { |language| language.name }

    if params[:q].present?
      @original = params[:q][:video_programme_title_or_video_foreign_language_title_cont_any]
      @the = params[:q][:video_programme_title_or_video_foreign_language_title_cont_any][0..3].downcase if params[:q][:video_programme_title_or_video_foreign_language_title_cont_any].present?
      if @the == 'the ' && params[:q][:video_programme_title_or_video_foreign_language_title_cont_any].present?
        @title = params[:q][:video_programme_title_or_video_foreign_language_title_cont_any][4..-1].downcase
        params[:q][:video_programme_title_or_video_foreign_language_title_cont_any] = ["#{@original}", "#{@title}, the"]
      end
    end

    if params[:q].present?
      @original_episode = params[:q][:episode_title_cont_any]
      @the_episode = params[:q][:episode_title_cont_any][0..3].downcase if params[:q][:episode_title_cont_any].present?
      if @the_episode == 'the ' && params[:q][:episode_title_cont_any].present?
        @title_episode = params[:q][:episode_title_cont_any][4..-1].downcase
        puts params[:q][:episode_title_cont_any] = ["#{@original_episode}", "#{@title_episode}, the"]
      end
    end

    @search = Screener.includes(:video)
                      .ransack(view_context.empty_blank_params params[:q])

    @screeners = @search.result(distinct: true)
                        .order("screeners.id DESC")
                        .paginate(page: params[:page],
                                  per_page: items_per_page.present? ? items_per_page : 100)

    @screeners = params[:active] == '1' ? @screeners.where(active: false) : @screeners.where(active: true)

    @screeners_count = @screeners.count

    if @screeners_count == 1
      redirect_to(edit_screener_path(@screeners.first))
    end

    session[:screeners_search] = collection_to_id_array(@screeners)
  end

  def new
    @languages = MasterLanguage.order("name")
                               .collect { |language| language.name }
    @screener = Screener.new
    @screener.video_id = params[:id]

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def create
    @screener = Screener.new(params[:screener])

    if @screener.save
      respond_to do |format|
        flash[:notice] = "Successfully created screener."
        format.js { render layout: false }
      end
    else
      respond_to do |format|
        format.js { render action: 'error.js.erb',
                           layout: false }
      end
    end
  end

  def edit
    @languages = MasterLanguage.order("name")
                               .collect { |language| language.name }

    if !params[:q].nil?
      @search = Screener.ransack(view_context.empty_blank_params params[:q])
      @screeners = @search.result(distinct: true)
                          .paginate(page: params[:page],
                                    per_page: items_per_page.present? ? items_per_page : 100)
    else
      #no search made yet
      @search = Screener.ransack(view_context.empty_blank_params params[:q])
      @screeners = @search.result(distinct: true)
                          .order("screeners.id DESC")
                          .paginate(page: params[:page],
                                    per_page: items_per_page.present? ? items_per_page : 100)
    end
    @screeners_count = @screeners.count,

        if !session[:screeners_search].nil?
          ids = session[:screeners_search]
          id = ids.index(params[:id].to_i)
          if !id.nil?
            @next_id = ids[id+1] if (id+1 < ids.count)
            @prev_id = ids[id-1] if (id-1 >= 0)
          end
        end

    @screener = Screener.find(params[:id])

    respond_to do |format|
      format.js { render layout: false }
      format.html {}
    end
  end


  def update

    @screener = Screener.find(params[:id])

    if @screener.update_attributes(params[:screener])
      respond_to do |format|
        format.html {
          flash[:notice] = "Successfully updated screener."
          redirect_to edit_screener_url(@screener.id)
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
    @screener = Screener.find(params[:id])

    if permitted_to? :admin_delete,
                     :screeners
      #check if video is in any playlists
      tot_playlists = ScreenerPlaylistItem.count(conditions: 'screener_id=' + @screener.id.to_s)

      if tot_playlists.zero?
        @screener.destroy
        flash[:notice] = "Successfully deleted screener."
        @screener_is_deleted = true

      else
        @screener.active = false
        @screener.save
        flash[:notice] = "Successfully deactivated screener."

        # flash[:notice] = 'Screener could not be deleted, screener is in use by playlists '
        @screener_is_deleted = true
      end

    end

    respond_to do |format|
      format.html { redirect_to(screeners_url) }
      format.js { render layout: false }
    end
  end

  def duplicate
    @screener = Screener.find(params[:id])
    @duplicated_screener = Screener.create(@screener.attributes)

    respond_to do |format|
      format.html { redirect_to edit_video_url(@screener.video.id) }
      format.js { render layout: false }
    end
  end

end