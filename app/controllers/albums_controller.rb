require 'amazon/aws'
require 'amazon/aws/search'

include Amazon::AWS
include Amazon::AWS::Search

class AlbumsController < ApplicationController
  before_filter :require_user
  filter_access_to :all
  cache_sweeper :album_sweeper

  def index
    if !params['search'].nil? 
      @search = Album.new_search(params[:search])
    else 
      @search = Album.new_search(:order_by => :id, :order_as => "DESC")
    end
    @albums, @albums_count = @search.all, @search.count
  end

  def show    
    @album = Album.find(params[:id])
    @tracks = Track.find(:all, :conditions => {:album_id => params[:id]})
    @playlists = AlbumPlaylistItem.find(:all, :conditions=>['album_id=?', params[:id]])
  end

  def edit
    @album = Album.find(params[:id])
    @tracks = Track.find(:all, :order=> 'track_num', :conditions => {:album_id => params[:id]})
  end

  def amazon_cd_covers
    @album = Album.find(params[:id])
    request  = Request.new( key_id, associates_id, "us" )
    @is = ItemSearch.new( 'Music', { 'Artist' => @album.artist_original , 'Keywords' => @album.title_original } )
    rg = ResponseGroup.new( 'Images' )
    @is.response_group = ResponseGroup.new(:Images)

    # Search for the items, passing the result into a block.
    #
    nr_items = 0
    page_nr = 0
        
    begin
#      @response = request.search( @is, rg, :ALL_PAGES ) 
      @response = request.search( @is, 1) 
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
      format.xml  { render :xml => @album }
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
        format.html { render :action => "new" }
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
            g = g + ", " + genre.name
          end
          i+=1
        end
        @album.genre = g
        @album.total_duration = @album.duration
        @album.save(false)

        #set defaults for tracks
        @album.tracks.each do |track|
          track.label = @album.label.name if !@album.label_id.nil?
          #update all tracks with values from album (genre, gender, origin, language)
          track.language_id = @album.language_id if track.language_id.nil?
          track.origin_id = @album.origin_id if track.origin_id.nil?
          track.gender = @album.gender if track.gender.nil?
          track.genres = @album.genres if track.genres.empty? && !params[:album][:genre_ids].nil?
          track.genre = @album.genre
          track.save(false)          
        end

        flash[:notice] = 'Album was successfully updated.'
        format.html { redirect_to edit_album_path(@album) }
      else
        @tracks = Track.find(:all, :order=> 'track_num', :conditions => {:album_id => params[:id]})
        format.html { render :action => "edit" }
      end

    end      
  end

  def destroy
    @album = Album.find(params[:id])	

    tot_albumplaylistitems =AlbumPlaylistItem.count(:conditions => 'album_id=' + params[:id] )	
    tot_audioplaylisttracks =AudioPlaylistTrack.count(:joins => 'left join tracks on tracks.id=audio_playlist_tracks.track_id', :conditions => 'album_id=' + params[:id] )		

    if  tot_albumplaylistitems.zero? && tot_audioplaylisttracks.zero?
      if permitted_to? :admin_delete, :albums
        Track.delete_all "album_id =" + params[:id]
        
        require 'xmlrpc/client' 
        begin 
          client = XMLRPC::Client.new2(Settings.nas_url) 
          client.timeout=10     
          result = client.call('delete_album_folder', Settings.iim_app_id, @album.id.to_s)
        #rescue Timeout::Error => e
        rescue Exception => e
          flash[:notice] = 'Could not connect to NAS to delete album mp3s - ' + e.message
        end
        
        @album.destroy 
        @album_is_deleted = true
        
      else
        Track.update_all "to_delete = 1", "album_id=" + params[:id]
        @album.to_delete = true
        @album.save(false)
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

  def add_track

  end

  def create_track

    track = params[:track]

    @track = Track.new(track)
    @track.duration = (params[:dur_min].to_i * 60  *1000) + (params[:dur_sec].to_i * 1000)
    @track.track_num = Track.count(:conditions => {:album_id => track[:album_id]})

    respond_to do |format|
      if @track.save
        flash[:notice] = 'Track was successfully created.'
        format.html { redirect_to(albums_path) }
        format.js

      end
    end

  end

  def show_genre
    @genres = Genre.find(:all)    
    @album = Album.find(params[:id])
  end

  def show_synopsis
    @album = Album.find(params[:id])
  end

  def show_tracks
    @tracks = Track.find(:all, :conditions => {:album_id => params[:id]})  
  end

  def show_playlists
    @tracks = Track.find(:all, :conditions => {:album_id => params[:id]})  
    @playlists = AlbumPlaylistItem.find(:all, :conditions=>['album_id=?', params[:id]], :group=>:album_playlist_id)
  end

  def show_tracks_translation
    @tracks = Track.find(:all, :conditions => {:album_id => params[:id]})  
  end


  def sort
    params[:tracklist].each_with_index do |id, pos|
      Track.find(id).update_attribute(:track_num, pos+1)
    end
    render :nothing => true
  end

  def restore
    @album = Album.find(params[:id])
    Track.update_all "to_delete = 0", "album_id=" + params[:id]
    @album.to_delete = false
    @album.save(false)
    flash[:notice] = 'Album has been restored'
    respond_to do |format|
        format.html { redirect_to(:back) }
        format.js
    end  
  end

end
