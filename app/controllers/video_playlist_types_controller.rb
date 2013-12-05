class VideoPlaylistTypesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @video_playlist_type = VideoPlaylistType.new
  end

  def index
    @video_playlist_types = VideoPlaylistType.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @video_playlist_type = VideoPlaylistType.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @video_playlist_type = VideoPlaylistType.new params[:video_playlist_type]

    respond_to do |format|
      if @video_playlist_type.save
        format.html { redirect_to @video_playlist_type,
                                  notice: 'Video Playlist Type was successfully created.' }
        format.json { render json: @video_playlist_type,
                             status: :created,
                             location: @video_playlist_type }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @video_playlist_type.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @video_playlist_type = VideoPlaylistType.find(params[:id])

    respond_to do |format|
      if @video_playlist_type.update_attributes(params[:video_playlist_type])
        #Movie.update_all(["video_playlist_type_cache=?",@video_playlist_type.name],["video_playlist_type_id=?",@video_playlist_type.id] )
        flash[:notice] = 'VideoPlaylistType was successfully updated.'
        format.html { redirect_to(video_playlist_types_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]
    @master_playlists = VideoPlaylist.where("video_playlist_type_id = ?", id)
    @screener_playlists = ScreenerPlaylist.where("video_playlist_type_id = ?", id)
    if @master_playlists.length.zero? && @screener_playlists.length.zero?
      @video_playlist_type = VideoPlaylistType.find(id)
      @video_playlist_type.destroy
    else
      flash[:notice] = 'VideoPlaylistType could not be deleted,
video_playlist_type is in use in some tracks'
    end

    respond_to do |format|
      format.html { redirect_to(video_playlist_types_url) }
    end
  end
end