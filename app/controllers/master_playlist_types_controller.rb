class MasterPlaylistTypesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @master_playlist_type = MasterPlaylistType.new
  end

  def index
    @master_playlist_types = MasterPlaylistType.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @master_playlist_type = MasterPlaylistType.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @master_playlist_type = MasterPlaylistType.new params[:master_playlist_type]

    respond_to do |format|
      if @master_playlist_type.save
        format.html { redirect_to @master_playlist_type,
                                  notice: 'Master Playlist Type was successfully created.' }
        format.json { render json: @master_playlist_type,
                             status: :created,
                             location: @master_playlist_type }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @master_playlist_type.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @master_playlist_type = MasterPlaylistType.find(params[:id])

    respond_to do |format|
      if @master_playlist_type.update_attributes(params[:master_playlist_type])
        #Movie.update_all(["master_playlist_type_cache=?",@master_playlist_type.name],["master_playlist_type_id=?",@master_playlist_type.id] )
        flash[:notice] = 'MasterPlaylistType was successfully updated.'
        format.html { redirect_to(master_playlist_types_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]
    @master_playlists = VideoMasterPlaylist.where("master_playlist_type_id = ?",
                                                  id)
    if @master_playlists.length.zero?
      @master_playlist_type = MasterPlaylistType.find(id)
      @master_playlist_type.destroy
    else
      flash[:notice] = 'MasterPlaylistType could not be deleted,
master_playlist_type is in use'
    end

    respond_to do |format|
      format.html { redirect_to(master_playlist_types_url) }
    end
  end
end