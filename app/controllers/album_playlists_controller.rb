require "spreadsheet"
require 'stringio'
include Iim

class AlbumPlaylistsController < ApplicationController
layout "layouts/application" ,  :except => :export
in_place_edit_for :album, :synopsis
in_place_edit_for :album_playlist_item, :category_id, :list_name => 'category', :list_attribute => 'name' 
before_filter :require_user
filter_access_to :all

  def index

    if !params['search'].nil?
      @search = AlbumPlaylist.new_search(params[:search])

    else 
      @search = AlbumPlaylist.new_search(:order_by => :id, :order_as => "DESC")
    end

    @album_playlists, @album_playlists_count = @search.all, @search.count
  end

  def new
    @album_playlist = AlbumPlaylist.new	
  end

  def create

    @album_playlist = AlbumPlaylist.new(params[:album_playlist])
    @album_playlist.user_id = current_user.id
    @album_playlist.locked = false;

    respond_to do |format|
      if @album_playlist.save
        flash[:notice] = 'Playlist was successfully created.'

        format.html { redirect_to(edit_album_playlist_path(@album_playlist)) }

      else
        format.html { render :action => "new" }

      end
    end
  end

  def edit 
    @album_playlist = AlbumPlaylist.find(params[:id],:include=>[:album_playlist_items,:albums])
  end 

  def update
    @album_playlist = AlbumPlaylist.find(params[:id])

    respond_to do |format|
      if @album_playlist.update_attributes(params[:album_playlist])
        flash[:notice] = 'Playlist was successfully updated.'
        format.html { redirect_to(:back) }

      else
        format.html { render :action => "edit" }

      end
    end
  end

  def show 
    @album_playlist = AlbumPlaylist.find(params[:id],:include=>[:album_playlist_items,:albums])
  end 

  def print

    @album_playlist = AlbumPlaylist.find(params[:id]) 	

    respond_to do  |format|
      format.html {render :layout => false }
    end
  end

  #display overlay
  def add_album_to_playlist

    if !params[:album_playlists].nil?
      @search = Album.new_search(params[:album_playlists])
      @search.conditions.to_delete_equals=0
      if !params[:search].nil?
        search = params[:search]
        @search.per_page = search[:per_page] if !search[:per_page].nil? 
        @search.page = search[:page] if !search[:page].nil?
      end
      @albums, @albums_count = @search.all, @search.count

    else
      @albums = nil
      @albums_count = 0
      @search = Album.new_search
    end
    # @search.conditions.to_delete_equals=0
    #     if params[:album_playlists].nil? && params[:search].nil?
    #       @search.order_by = :id
    #       @search.order_as = "DESC"
    #       @search.per_page = 10
    #     end

    respond_to do |format|
      format.html 

      format.js {
        if params[:album_playlists].nil? && params[:search].nil?
          render :action => 'add_album_to_playlist.rhtml', :layout => false 
        else
          render :update do |page| 
            page.replace_html "albums", :partial => "albums"
          end
        end      
      }
    end
  end

  def add_album

    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist_item = AlbumPlaylistItem.new(:album_playlist_id => params[:id], :category_id => 1, :album_id => params[:album_id], :position => @album_playlist.albums.count + 1)

    #check if album has been added to a previous playlist before    
    @playlists_with_album = AlbumPlaylistItem.find(:all, 
    :conditions=>"album_id=#{params[:album_id]}",
    :group=>"album_playlist_id")
    @notice=""

    @album_to_add = Album.find(params[:album_id])

    if !@playlists_with_album.empty? && params[:add].nil?
      @playlists_with_album.each do |playlist_item|
        @notice += "<br/><div id='exists'>Note! This album #{@album_to_add.id.to_s} exists in playlist <a href='/album_playlists/#{playlist_item.album_playlist_id.to_s}' target='_blank'>#{playlist_item.album_playlist_id.to_s} (#{playlist_item.album_playlist.client_playlist_code.to_s})</a></div>" if !playlist_item.album_playlist.nil?
      end     

    else
      if @album_playlist_item.save
        flash[:notice] = 'Album was successfully added.'
      end
    end
  end  

  def destroy
    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist.destroy

    respond_to do |format|
      format.html { redirect_to(album_playlists_path) }
      format.js
    end
  end

  def lock
    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist.locked = true
    @album_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was locked'
      format.html { redirect_to(album_playlists_path) }
    end
  end

  def unlock
    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist.locked = false
    @album_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was unlocked'
      format.html { redirect_to(album_playlists_path) }
    end
  end

  def sort
    params[:albumplaylist].each_with_index do |id, pos|
      AlbumPlaylistItem.find(id).update_attribute(:position, pos+1)
    end
    render :nothing => true
  end

  def edit_synopsis
    @album_playlist_item = AlbumPlaylistItem.find(params[:id]) 	

    respond_to do  |format|
      format.html
      format.js {render :action => 'edit_synopsis.rhtml', :layout => false }
    end
  end  

  def export_albums_programmed_per_airline_to_excel

    @album_playlist = params[:album_playlist]

    @album_playlist_items = AlbumPlaylistItem.find(:all, :joins=>"left join album_playlists on album_playlist_items.album_playlist_id=album_playlists.id", :conditions=>"album_playlists.airline_id=#{@album_playlist["airline_id"]}" )

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Airline", "Album Title", "Artist", "Start Month", "End Month"]


    @album_playlist_items.each do |item|
      if !item.album.nil?
        sheet.add_row [item.album_playlist.airline.name, item.album.title_original, item.album.artist_original, item.album_playlist.start_playdate.strftime("%B"), item.album_playlist.end_playdate.strftime("%B")]
      else
        sheet.add_row ["album missing"]
      end
    end

    bold = Spreadsheet::Format.new :weight => :bold
    5.times do |x| book.worksheets[0].row(0).set_format(x, bold) end

      data = StringIO.new ''
      book.write data
      send_data data.string, :type=>"application/excel", 
      :disposition=>'attachment', :filename => 'airline_aod.xls'

  end

  def export_to_excel
    @album_playlist = AlbumPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Client Playlist Code", "Airline Code", "Airline Name", "Playdate Start Month", "Playdate Start Year", "Playdate End Month", "Playdate End Year"]

    if @album_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @album_playlist.airline.code
      airline_name = @album_playlist.airline.name
    end

    sheet.add_row [@album_playlist.client_playlist_code, airline_code, airline_name, @album_playlist.start_playdate.strftime("%B"),  @album_playlist.start_playdate.strftime("%Y"), @album_playlist.end_playdate.strftime("%B"),  @album_playlist.end_playdate.strftime("%Y")]

    sheet.add_lines(1)
    
    album_playlist_items = @album_playlist.album_playlist_items_sorted
    
    # Album Playlist Summary
    # header row
    sheet.add_row ["Position", "Category", "CD Code", "Album Title (Original)", "Album Title (Translated)", "Albums Artist (Original)", "Album Artist (Translated)", "Label", "Synopsis", "Album Duration"]

    # data rows
    album_playlist_items.each do |album_playlist_item|
      if !album_playlist_item.album.label_id.nil?
        label = album_playlist_item.album.label.name 
      else
        label =""
      end

      sheet.add_row [album_playlist_item.position, album_playlist_item.category.name, 
        album_playlist_item.album.cd_code, 
        album_playlist_item.album.title_original, 
        album_playlist_item.album.title_english, 
        album_playlist_item.album.artist_original, 
        album_playlist_item.album.artist_english, 
        label, 
        album_playlist_item.album.synopsis, 
        album_playlist_item.album.duration_in_min]
      end

      sheet.add_lines(1)

      # Album Playlist details with tracks
      # header row
      sheet.add_row [ "Position", "Label", "Album Title (Translated)", "Album Title (Original)", "Songs Artist (Translated)", "Songs Artist (Original)", "Songs Track Number","Songs Track Title (Translated)", "Songs Track Title (Original)","Song Duration"]   

      # data rows
      album_playlist_items.each do |album_playlist_item|
        
        if !album_playlist_item.album.label_id.nil?
          label = album_playlist_item.album.label.name 
        else
          label =""
        end

        album_playlist_item.album.tracks_sorted.each do |track|

          dur = duration track.duration
          
          track_num = convert_to_two_digits(track.track_num)

          sheet.add_row [album_playlist_item.position,
            label, 
            album_playlist_item.album.title_english, 
            album_playlist_item.album.title_original, 
            track.artist_english, 
            track.artist_original, 
            track_num, track.title_english, track.title_original, dur ]  
                        
          end
          
        end

        data = StringIO.new ''
        book.write data
        send_data data.string, :type=>"application/excel", 
        :disposition=>'attachment', :filename => "album_playlist_#{@album_playlist.id}.xls"
      end

      def duration ms
        if !ms.nil?

          sec = ms/1000

          min = sec/60

          sec = sec%60

          if sec < 10 :  sec = "0#{sec}"
          end 
          if sec == 0 :  sec = "00"
          end
          if min == 0 :  min = "0"
          end

          t = "#{min}:#{sec}"
        else 
          t = "0:00"
        end
        t
      end

      def duplicate

        @album_playlist = AlbumPlaylist.find(params[:id])
        @album_playlist_duplicate = AlbumPlaylist.new
        @album_playlist_duplicate.client_playlist_code = @album_playlist.client_playlist_code
        @album_playlist_duplicate.airline_id = @album_playlist.airline_id
        @album_playlist_duplicate.in_out = @album_playlist.in_out
        @album_playlist_duplicate.start_playdate = @album_playlist.start_playdate
        @album_playlist_duplicate.end_playdate = @album_playlist.end_playdate
        @album_playlist_duplicate.user_id = current_user.id         
        @album_playlist_duplicate.save

        @album_playlist.album_playlist_items.each do |item|

          AlbumPlaylistItem.create(
          :album_id => item.album_id,
          :position => item.position,
          :category_id => item.category_id,
          :album_playlist_id => @album_playlist_duplicate.id
          )

        end

        respond_to do |format|
          format.html { redirect_to(album_playlists_path) }
        end
      end
      
      def download_mp3

        @playlist_id = params[:id]
        playlist = AlbumPlaylist.find(@playlist_id)

        albums_found = playlist.album_playlist_items_sorted.delete_if{|playlist_album| playlist_album.album.mp3_exists==false}

        #track_names = tracks_found.map{|t| t.position.to_s + "-" + t.track.title_original }.flatten
        album_positions = albums_found.map{|t| t.position.to_s }.flatten
        album_ids = albums_found.map{|t| t.album_id }.flatten
        total_tracks = albums_found.map{|t| t.album.tracks_count }.flatten

        require 'xmlrpc/client' 
        client = XMLRPC::Client.new2(Settings.nas_url)       
        begin  
          result = client.call('create_albums_zip', Settings.iim_app_id, @playlist_id, album_positions, album_ids, total_tracks)
        rescue Timeout::Error => e
          flash[:notice] = 'Could not connect to NAS'
        end
        
        if result
          respond_to do |format|
            format.js {
              render :action => 'download_mp3.rhtml', :layout => false
            }
          end
        end

      end
end
