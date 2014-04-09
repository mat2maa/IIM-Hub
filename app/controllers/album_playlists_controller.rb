require 'spreadsheet'
require 'stringio'
include TimeUtils

class AlbumPlaylistsController < ApplicationController
  layout "layouts/application",
         except: :export
=begin
  in_place_edit_for :album,
                    :synopsis
  in_place_edit_for :album_playlist_item,
                    :category_id,
                    list_name: 'category',
                    list_attribute: 'name'
=end
  before_filter :require_user
  before_filter :get_columns
  filter_access_to :all

  def index
    @search = AlbumPlaylist.includes(:airline)
    .ransack(view_context.empty_blank_params params[:q])
    if !params[:q].nil?
      @album_playlists = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    else
      @album_playlists = @search.result(distinct: true)
      .order("album_playlists.id DESC")
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    end
    @album_playlists_count = @album_playlists.count
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
        format.html { render action: "new" }
        format.json { render json: @album_playlist.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit

    @search = AlbumPlaylist.includes(:airline)
    .ransack(view_context.empty_blank_params params[:q])
    if !params[:q].nil?
      @album_playlists = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    else
      @album_playlists = @search.result(distinct: true)
      .order("album_playlists.id DESC")
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    end
    @album_playlists_count = @album_playlists.count

    @album_playlist = AlbumPlaylist.includes(album_playlist_items: :album)
    .find(params[:id])
  end

  def update
    @album_playlist = AlbumPlaylist.find(params[:id])

    @search = AlbumPlaylist.includes(:airline)
    .ransack(view_context.empty_blank_params params[:q])
    if !params[:q].nil?
      @album_playlists = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    else
      @album_playlists = @search.result(distinct: true)
      .order("album_playlists.id DESC")
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    end
    @album_playlists_count = @album_playlists.count

    respond_to do |format|
      if @album_playlist.update_attributes(params[:album_playlist])
        flash[:notice] = 'Playlist was successfully updated.'
        format.html { redirect_to(:back) }
        format.json { respond_with_bip(@album_playlist) }
      else
        format.html { render action: "edit" }
        format.json { respond_with_bip(@album_playlist) }
      end
    end
  end

  def show
    @album_playlist = AlbumPlaylist.includes([:album_playlist_items, {album_playlist_items: :album}, {album_playlist_items: :category}])
    .find(params[:id])
  end

  def print

    @album_playlist = AlbumPlaylist.find(params[:id])

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  #display overlay
  def add_album_to_playlist

    @album_playlist = AlbumPlaylist.find(params[:id])

    @search = Album.ransack(view_context.empty_blank_params params[:q])
    @albums = @search.result(distinct: true)
    .where("to_delete = ?", "0")
    .order("albums.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    @albums_count = @albums.count

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def add_album

    @album_playlist = AlbumPlaylist.find(params[:id])

    @album_playlist_item_position = AlbumPlaylistItem.where("album_playlist_id=?", params[:id])
    .order("position ASC")
    .find(:last)
    @album_playlist_item_position = @album_playlist_item_position.nil? ? 1 : @album_playlist_item_position.position + 1

    @album_playlist_item = AlbumPlaylistItem.new(album_playlist_id: params[:id],
                                                 category_id: 1,
                                                 album_id: params[:album_id],
                                                 position: @album_playlist_item_position)

    #check if album has been added to a previous playlist before    
    @playlists_with_album = AlbumPlaylistItem.where("album_id=#{params[:album_id]}")
    .group("album_playlist_id")

    @notice=""

    @album_to_add = Album.find(params[:album_id])

    if !@playlists_with_album.empty? && params[:add].nil?
      @notice += "<ul>"
      @playlists_with_album.each do |playlist_item|
        @notice += "<li>#{@album_to_add.title_original.to_s} (#{@album_to_add.id.to_s}) exists in playlist <a href='/album_playlists/#{playlist_item.album_playlist_id.to_s}' target='_blank' style='color: rgb(0,100,100);'>#{playlist_item.album_playlist_id.to_s} (#{playlist_item.album_playlist.client_playlist_code.to_s})</a></li>" if !playlist_item.album_playlist.nil?
      end
      @notice += "</ul>"
    else
      if @album_playlist_item.save
        flash[:notice] = 'Album was successfully added.'
      end
    end

    respond_to do |format|
      format.html {}
      format.js
    end
  end

  #add selected albums to playlist
  def add_multiple_albums

    @notice = ""
    @album_playlist = AlbumPlaylist.find(params[:playlist_id])
    album_ids = params[:album_ids]

    album_ids.each do |album_id|
      @album_playlist_item_position = AlbumPlaylistItem.where('album_playlist_id = ?', params[:playlist_id])
      .order('position ASC')
      .find(:last)
      @album_playlist_item_position = @album_playlist_item_position.nil? ? 1 : @album_playlist_item_position.position + 1
      @album_playlist_item = AlbumPlaylistItem.new(album_playlist_id: params[:playlist_id],
                                                   category_id: 1,
                                                   album_id: album_id,
                                                   position: @album_playlist_item_position)

      if @album_playlist_item.save
        flash[:notice] = 'Albums were successfully added to playlist.'
        @notice = 'Albums were successfully added to playlist.'
        session[:albums_search] = collection_to_id_array(@album_playlist.albums)
      end
    end # loop through album ids

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
    render nothing: true
  end

  def edit_synopsis
    @album_playlist_item = AlbumPlaylistItem.find(params[:id])

    respond_to do |format|
      format.html
      format.js { render action: 'edit_synopsis.rhtml',
                         layout: false }
    end
  end

  def export_albums_programmed_per_airline_to_excel

    @album_playlist = params[:album_playlist]

    @album_playlist_items = AlbumPlaylistItem.joins("left join album_playlists on album_playlist_items.album_playlist_id=album_playlists.id")
    .where("album_playlists.airline_id=#{@album_playlist["airline_id"]}")

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Airline",
                   "Album Title",
                   "Artist",
                   "Start Month",
                   "End Month"]


    @album_playlist_items.each do |item|
      if !item.album.nil?
        sheet.add_row [item.album_playlist.airline.name,
                       item.album.title_original,
                       item.album.artist_original,
                       item.album_playlist.start_playdate.strftime("%B"),
                       item.album_playlist.end_playdate.strftime("%B")]
      else
        sheet.add_row ["album missing"]
      end
    end

    bold = Spreadsheet::Format.new weight: :bold
    5.times do |x|
      book.worksheets[0].row(0).set_format(x,
                                           bold)
    end

    data = StringIO.new ''
    book.write data
    send_data data.string,
              type: "application/excel",
              disposition: 'attachment',
              filename: 'airline_aod.xls'

  end

  def export_to_excel
    @album_playlist = AlbumPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Client Playlist Code",
                   "Airline Code",
                   "Airline Name",
                   "Playdate Start Month",
                   "Playdate Start Year",
                   "Playdate End Month",
                   "Playdate End Year"]

    if @album_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @album_playlist.airline.code
      airline_name = @album_playlist.airline.name
    end

    sheet.add_row [@album_playlist.client_playlist_code,
                   airline_code,
                   airline_name,
                   @album_playlist.start_playdate.strftime("%B"),
                   @album_playlist.start_playdate.strftime("%Y"),
                   @album_playlist.end_playdate.strftime("%B"),
                   @album_playlist.end_playdate.strftime("%Y")]

    sheet.add_lines(1)

    album_playlist_items = @album_playlist.album_playlist_items_sorted

    # Album Playlist Summary
    # header row
    sheet.add_row ["Position",
                   "Category",
                   "CD Code",
                   "Album Title (Original)",
                   "Album Title (Translated)",
                   "Albums Artist (Original)",
                   "Album Artist (Translated)",
                   "Label",
                   "Synopsis",
                   "Album Duration"]

    # data rows
    album_playlist_items.each.with_index do |album_playlist_item, index|
      if !album_playlist_item.album.label_id.nil?
        label = album_playlist_item.album.label.name
      else
        label =""
      end

      sheet.add_row [index + 1,
                     album_playlist_item.category.name,

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
    sheet.add_row ["Position",
                   "Label",
                   "Album Title (Translated)",
                   "Album Title (Original)",
                   "Songs Artist (Translated)",
                   "Songs Artist (Original)",
                   "Songs Track Number", "Songs Track Title (Translated)",
                   "Songs Track Title (Original)", "Song Duration"]

    # data rows
    album_playlist_items.each.with_index do |album_playlist_item, index|

      if !album_playlist_item.album.label_id.nil?
        label = album_playlist_item.album.label.name
      else
        label =""
      end

      album_playlist_item.album.tracks_sorted.each do |track|

        dur = duration track.duration

        track_num = convert_to_two_digits(track.track_num)

        sheet.add_row [index + 1,
                       label,

                       album_playlist_item.album.title_english,

                       album_playlist_item.album.title_original,

                       track.artist_english,

                       track.artist_original,

                       track_num,
                       track.title_english,
                       track.title_original,
                       dur]

      end

    end

    data = StringIO.new ''
    book.write data
    send_data data.string,
              type: "application/excel",
              disposition: 'attachment',
              filename: "album_playlist_#{@album_playlist.id}.xls"
  end

  def duration ms
    if !ms.nil?

      sec = ms/1000

      min = sec/60

      sec = sec%60

      if  sec < 10 then
        sec = "0#{sec}"
      end
      if  sec == 0 then
        sec = "00"
      end
      if  min == 0 then
        min = "0"
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
          album_id: item.album_id,
          position: item.position,
          category_id: item.category_id,
          album_playlist_id: @album_playlist_duplicate.id
      )

    end

    respond_to do |format|
      format.html { redirect_to(album_playlists_path) }
    end
  end

  def download_album_playlist
    # Set up XMLRPC Client. Server located at https://imagesinmotion.no-ip.biz/server/audio_file_operations.php
    app_id = Settings.iim_app_id
    nas_url = Settings.nas_url

    client = XMLRPC::Client.new_from_uri(nas_url)

    client.disableSSLVerification()
    client.http_header_extra = {'Content-Type' => 'text/xml'}
    client.timeout = nil

    # Reset DB
    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist.update_attributes job_current_progress: nil,
                                      job_current_track: nil,
                                      job_id: nil,
                                      job_finished_at: nil,
                                      job_total_tracks: nil

    # Gather data
    @albums_found = @album_playlist.album_playlist_items_sorted.delete_if { |playlist_album| !playlist_album.album.mp3_exists }

    @album_positions = @albums_found.map { |t| t.position.to_s }.flatten
    @albums = @albums_found.map { |t| t.album_id }.flatten
    @tracks = @albums_found.map { |t| t.album.tracks_count }.flatten

    # Call
    begin
      result = client.call2('create_albums_zip', app_id, params[:id], @albums, @tracks, @album_positions)
    rescue Timeout::Error => e
      puts 'Could not connect to NAS'
    end

    # Callback
    if result
      puts result
      flash[:notice] = 'Zip file created successfully.'
      @album_playlist.update_attribute :job_finished_at, Time.current
      respond_to do |format|
        format.js
      end
    end
  end

  def delete_album_playlist_zip
    # Set up XMLRPC Client. Server located at https://imagesinmotion.no-ip.biz/server/audio_file_operations.php
    app_id = Settings.iim_app_id
    nas_url = Settings.nas_url

    client = XMLRPC::Client.new_from_uri(nas_url)

    client.disableSSLVerification()
    client.http_header_extra = {'Content-Type' => 'text/xml'}
    client.timeout = nil

    # Reset DB
    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist.update_attributes job_current_progress: nil,
                                      job_current_track: nil,
                                      job_id: nil,
                                      job_finished_at: nil,
                                      job_total_tracks: nil

    # Call
    begin
      result = client.call2('delete_albums_zip', app_id, params[:id])
    rescue Timeout::Error => e
      flash[:notice] = 'Could not connect to NAS'
    end

    # Callback
    if result
      puts result
      flash[:notice] = 'Zip file deleted successfully.'
      respond_to do |format|
        format.js
      end
    end
  end

  def table_column_select
    puts session[:album_playlist_checked] = params[:checked]
    render nothing: true
  end

  def sort_alphabetically
    @album_playlist = AlbumPlaylist.find(params[:id])
    @album_playlist_items = @album_playlist.album_playlist_items

    puts params[:sort]

    if params[:sort] == 'title'
      @album_playlist_items.sort_by! { |m| m.album.title_original.downcase }.each.with_index do |t, index|
        t.update_attribute :position_position, index
      end
    elsif params[:sort] == 'artist'
      @album_playlist_items.sort_by! { |m| [m.album.artist_original.downcase, m.album.title_original.downcase] }.each.with_index do |t, index|
        t.update_attribute :position_position, index
      end
    end

    redirect_to :back
  end

  private

  def get_columns
    @columns = ['#', 'Title', 'Artist', 'CD Code', 'Duration', 'Tracks', 'Album Title (Translated)', 'Artist (Translated)', 'Label', 'Explicit Lyrics', 'Synopsis', 'Genre']
  end

end