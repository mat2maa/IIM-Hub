require 'amazon/aws'
require 'amazon/aws/search'

include Amazon::AWS
include Amazon::AWS::Search

class AlbumsController < ApplicationController
  before_filter :require_user, except: [:create_from_json]
  before_filter :require_http_auth_user, only: [:create_from_json]
  protect_from_forgery except: :create_from_json
  filter_access_to :all
  cache_sweeper :album_sweeper

  respond_to :json

  def index
    @search = Album.includes(:label)
    .ransack(params[:q])
    @albums = @search.result(distinct: true)
    .order("albums.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page)

    @albums_count = @albums.count
  end

  def show
    @album = Album.find(params[:id])
    @tracks = Track.where(album_id: params[:id])
    @playlists = AlbumPlaylistItem.where('album_id=?',
                                         params[:id])
  end

  def edit
    @album = Album.find(params[:id])
    @tracks = Track.where(album_id: params[:id]).order('track_num')
  end

  def amazon_cd_covers
    @album = Album.find(params[:id])
    request = Request.new(key_id,
                          associates_id,
                          "us")
    @is = ItemSearch.new('Music',
                         {'Artist' => @album.artist_original,
                          'Keywords' => @album.title_original})
    rg = ResponseGroup.new('Images')
    @is.response_group = ResponseGroup.new(:Images)

    # Search for the items,passing the result into a block.
    nr_items = 0
    page_nr = 0

    begin
      # @response = request.search( @is, rg, :ALL_PAGES)
      @response = request.search(@is,
                                 1)
      @images = ''

      if !@response.length.nil?
        if !@response[0].item_search_response[0].items[0].nil?
          @response[0].item_search_response[0].items[0].item.each do |item|
            if !item.large_image.url.nil?
              p item.large_image.url
              @images += "<img src='#{item.large_image.url}'/><br/>"
            end
          end
        end
      else
        @response.item_search_response[0].items[0].item.each do |item|
          if !item.large_image.url.nil?
            p item.large_image.url
            @images += "<img src='#{item.large_image.url}'/><br/>"
          end
        end
      end
    rescue
      @images = "No images found"
    end

  end

  def new
    @album = Album.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @album }
    end
  end

  def create

    @album = Album.new(params[:album])
    @album.to_delete = 0

    respond_to do |format|
      if @album.save
        flash[:notice] = 'Album was successfully created.'
        #redirect_to(albums_path)
        format.html { redirect_to edit_album_path(@album) }
      else
        flash[:notice] = 'Album was NOT successfully created.'
        format.html { render action: "new" }
      end
    end
  end


  def create_from_json
    @album = Album.new(params[:album])
    @album.to_delete = 0

    respond_to do |format|
      format.json do
        if @album.save
          head :ok, location: @album
        else
          head 500
        end
      end
    end

  end

  def update
    @album = Album.find(params[:id])
    respond_to do |format|

      if @album.update_attributes(params[:album])

        i=0
        g=""
        @album.genres.each do |genre|
          if i==0
            g = genre.name
          else
            g = g + "," + genre.name
          end
          i+=1
        end
        @album.genre = g
        @album.total_duration = @album.duration
        @album.save(validate: false)

        #set defaults for tracks
        @album.tracks.each do |track|
          track.label = @album.label.name if !@album.label_id.nil?
          #update all tracks with values from album (genre, gender, origin, language)
          track.language_id = @album.language_id if track.language_id.nil?
          track.origin_id = @album.origin_id if track.origin_id.nil?
          track.gender = @album.gender if track.gender.nil?
          track.genres = @album.genres if track.genres.empty? && !params[:album][:genre_ids].nil?
          track.genre = @album.genre
          track.save(validate: false)
        end

        flash[:notice] = 'Album was successfully updated.'
        format.html { redirect_to edit_album_path(@album) }
        format.json { respond_with_bip(@album) }
      else
        @tracks = Track.where(album_id: params[:id]).order('track_num')
        format.html { render action: "edit" }
        format.json { respond_with_bip(@album) }
      end

    end
  end

  def add_track
    respond_to do |format|
      format.js
    end
  end

  def create_track

    track = params[:track]

    @track = Track.new(track)
    @track.duration = (params[:dur_min].to_i * 60 *1000) + (params[:dur_sec].to_i * 1000)
    @track.track_num = Track.count(conditions: {album_id: track[:album_id]})

    respond_to do |format|
      if @track.save
        flash[:notice] = 'Track was successfully created.'
        format.html { redirect_to(albums_path) }
        format.js

      end
    end

  end

  def show_genre
    @genres = Genre.all
    @album = Album.find(params[:id])
  end

  def show_synopsis
    @album = Album.find(params[:id])
  end

  def show_tracks
    @tracks = Track.where(album_id: params[:id])
  end

  def show_playlists
    @tracks = Track.where(album_id: params[:id])
    @playlists = AlbumPlaylistItem.where('album_id=?',
                                         params[:id]).group(:album_playlist_id)
  end

  def show_tracks_translation
    @tracks = Track.where(album_id: params[:id])
  end


  def sort
    params[:tracklist].each_with_index do |id,
        pos|
      Track.find(id).update_attribute(:track_num,
                                      pos+1)
    end
    render nothing: true
  end

  def restore
    @album = Album.find(params[:id])
    Track.update_all "to_delete = 0",
                     "album_id=" + params[:id]
    @album.to_delete = false
    @album.save(validate: false)
    flash[:notice] = 'Album has been restored'
    respond_to do |format|
      format.html { redirect_to(:back) }
      format.js
    end
  end

  def destroy
    @album = Album.find(params[:id])

    tot_albumplaylistitems =AlbumPlaylistItem.count(conditions: 'album_id=' + params[:id])
    tot_audioplaylisttracks =AudioPlaylistTrack.count(joins: 'left join tracks on tracks.id=audio_playlist_tracks.track_id',
                                                      conditions: 'album_id=' + params[:id])

    if  tot_albumplaylistitems.zero? && tot_audioplaylisttracks.zero?
      if permitted_to? :admin_delete,
                       :albums
        Track.delete_all "album_id =" + params[:id]

        Album.delay.delete_album(params[:id])

        @album.destroy
        @album_is_deleted = true

      else
        Track.update_all "to_delete = 1",
                         "album_id=" + params[:id]
        @album.to_delete = true
        @album.save(validate: false)
        flash[:notice] = 'Album will be deleted when approved by administrator'
      end
    else
      @album_is_deleted = false
      flash[:notice] = 'Album could not be deleted, album or track from album is in use by playlists'
    end

    respond_to do |format|
      format.html { redirect_to(:back) }
      format.js
    end
  end

end
