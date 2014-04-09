require 'spreadsheet'
require 'stringio'

class AudioPlaylistsController < ApplicationController

  layout "layouts/application",
         except: :export_to_excel
  before_filter :require_user, except: [:find_via_json]
  before_filter :require_http_auth_user, only: [:find_via_json]
  before_filter :get_columns
  protect_from_forgery except: :find_via_json

  filter_access_to :all

  respond_to :json

  def index
    @search = AudioPlaylist.includes(audio_playlist_tracks: :track)
    .ransack(view_context.empty_blank_params params[:q])
    if !params[:q].nil?
      @audio_playlists = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    else
      @audio_playlists = @search.result(distinct: true)
      .order("audio_playlists.id DESC")
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    end
    @audio_playlists_count = @audio_playlists.count
  end

  def show
    @audio_playlist = AudioPlaylist.includes(tracks: :origin)
    .find(params[:id])
  end

  def find_via_json
    @playlist_id = params[:id]
    playlist = AudioPlaylist.find(@playlist_id)
    tracks_found = playlist.audio_playlist_tracks_sorted.delete_if { |playlist_track| playlist_track.track.mp3_exists==false }

    playlist_positions = tracks_found.map { |t| t.position.to_s }.flatten
    album_ids = tracks_found.map { |t| t.track.album_id }.flatten
    track_nums = tracks_found.map { |t| t.track.track_num }.flatten

    respond_with [playlist_positions, album_ids, track_nums]
  end

  def print

    @audio_playlist = AudioPlaylist.find(params[:id])

    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def new
    @audio_playlist = AudioPlaylist.new
  end

  def create

    @audio_playlist = AudioPlaylist.new(params[:audio_playlist])
    @audio_playlist.user_id = current_user.id

    if !@audio_playlist.program_id.nil?
      @audio_playlist.program_cache = @audio_playlist.program.name
    else
      @audio_playlist.program_cache = ''
    end
    if !@audio_playlist.airline_id.nil?
      @audio_playlist.airline_cache = @audio_playlist.airline.name
    else
      @audio_playlist.airline_cache = ''
    end

    respond_to do |format|
      if @audio_playlist.save
        flash[:notice] = 'Playlist was successfully created.'
        format.html { redirect_to(edit_audio_playlist_path(@audio_playlist)) }
      else
        format.html { render action: "new" }
        format.json { render json: @audio_playlist.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @search = AudioPlaylist.includes(audio_playlist_tracks: :track)
    .ransack(view_context.empty_blank_params params[:q])
    if !params[:q].nil?
      @audio_playlists = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    else
      @audio_playlists = @search.result(distinct: true)
      .order("audio_playlists.id DESC")
      .paginate(page: params[:page],
                per_page: items_per_page)
    end
    @audio_playlists_count = @audio_playlists.count

    @audio_playlist = AudioPlaylist.includes([{audio_playlist_tracks: :track}, {tracks: :origin}])
    .find(params[:id])
  end

  def update
    @audio_playlist = AudioPlaylist.includes([{audio_playlist_tracks: :track}, {tracks: :origin}])
    .find(params[:id])

    @search = AudioPlaylist.includes(audio_playlist_tracks: :track)
    .ransack(view_context.empty_blank_params params[:q])
    if !params[:q].nil?
      @audio_playlists = @search.result(distinct: true)
      .paginate(page: params[:page],
                per_page: items_per_page.present? ? items_per_page : 100)
    else
      @audio_playlists = @search.result(distinct: true)
      .order("audio_playlists.id DESC")
      .paginate(page: params[:page],
                per_page: items_per_page)
    end
    @audio_playlists_count = @audio_playlists.count

    @audio_playlist = AudioPlaylist.includes([{audio_playlist_tracks: :track}, {tracks: :origin}])
    .find(params[:id])

    respond_to do |format|
      if @audio_playlist.update_attributes(params[:audio_playlist])
        if !@audio_playlist.program_id.nil?
          @audio_playlist.program_cache = @audio_playlist.program.name
        else
          @audio_playlist.program_cache = ''
        end
        if !@audio_playlist.airline_id.nil?
          @audio_playlist.airline_cache = @audio_playlist.airline.name
        else
          @audio_playlist.airline_cache = ''
        end
        @audio_playlist.save
        flash[:notice] = 'Playlist was successfully updated.'
        #format.html { redirect_to(audio_playlists_path) }

        #else
        format.html { render action: "edit" }
        format.json { respond_with_bip(@audio_playlist) }

      end
    end
  end

  def destroy
    @audio_playlist = AudioPlaylist.find(params[:id])
    @audio_playlist.destroy

    respond_to do |format|
      format.html { redirect_to(audio_playlists_path) }
      format.js
    end
  end

  def lock
    @audio_playlist = AudioPlaylist.find(params[:id])
    @audio_playlist.locked = true
    @audio_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was locked'
      format.html { redirect_to(audio_playlists_path) }
    end
  end

  def unlock
    @audio_playlist = AudioPlaylist.find(params[:id])
    @audio_playlist.locked = false
    @audio_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was unlocked'
      format.html { redirect_to(audio_playlists_path) }
    end
  end

  def duplicate

    @playlist = AudioPlaylist.find(params[:id])
    @playlist_duplicate = AudioPlaylist.create(

        client_playlist_code: @playlist.client_playlist_code,
        airline_id: @playlist.airline_id,
        in_out: @playlist.in_out,
        start_playdate: @playlist.start_playdate,
        end_playdate: @playlist.end_playdate,
        vo: @playlist.vo,
        program_id: @playlist.program_id,
        user_id: current_user.id,
        airline_cache: @playlist.airline_cache,
        program_cache: @playlist.program_cache

    )

    @playlist.audio_playlist_tracks.each do |item|

      AudioPlaylistTrack.create(
          track_id: item.track_id,
          position: item.position,
          audio_playlist_id: @playlist_duplicate.id
      )

    end

    respond_to do |format|
      format.html { redirect_to(audio_playlists_path) }
    end
  end

  #display overlay
  def add_track_to_playlist

    @audio_playlist = AudioPlaylist.find(params[:id])

    dur_min = (params[:dur_min_min].to_i * 60 *1000) + (params[:dur_min_sec].to_i * 1000)
    dur_max = (params[:dur_max_min].to_i * 60 *1000) + (params[:dur_max_sec].to_i * 1000)

    @search = Track.ransack(view_context.empty_blank_params params[:q])
    @tracks = @search.result(distinct: true)
    .order("tracks.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page)

    unless dur_max.zero?
      @tracks = @tracks.greater_than_dur_min(dur_min)
      @tracks = @tracks.less_than_dur_max(dur_max)
    end

    @tracks_count = @tracks.count

    respond_to do |format|
      format.js { render layout: false }
    end
  end


  def add_track

    @audio_playlist = AudioPlaylist.find(params[:id])

    @audio_playlist_track_position = AudioPlaylistTrack.where("audio_playlist_id=?", params[:id])
    .order("position ASC")
    .find(:last)
    @audio_playlist_track_position = @audio_playlist_track_position.nil? ? 1 : @audio_playlist_track_position.position + 1

    @audio_playlist_track = AudioPlaylistTrack.new(audio_playlist_id: params[:id],
                                                   track_id: params[:track_id],
                                                   position: @audio_playlist_track_position)

    #check if track has been added to a previous playlist before
    @playlists_with_track = AudioPlaylistTrack.where("track_id = ?", params[:track_id])
    .group("audio_playlist_id")

    @notice=""

    @track_to_add = Track.find(params[:track_id])

    if !@playlists_with_track.empty? && params[:add].nil?
      @notice += "<ul>"
      @playlists_with_track.each do |playlist_item|
        @notice += "<li>#{@track_to_add.title_original.to_s} (#{@track_to_add.id.to_s}) exists in playlist <a href='/audio_playlists/#{playlist_item.audio_playlist_id.to_s}' target='_blank' class='alert-link'>#{playlist_item.audio_playlist_id.to_s} (#{playlist_item.audio_playlist.client_playlist_code.to_s})</a></li>" if !playlist_item.audio_playlist.nil?
      end
      @notice += "</ul>"
    else
      if @audio_playlist_track.save
        flash[:notice] = 'Track was successfully added.'
      end
    end

    respond_to do |format|
      format.html {}
      format.js
    end
  end

  #add selected tracks to playlist
  def add_multiple_tracks

    @notice = ""
    @notice_array = []
    @tracks_to_add = []
    @audio_playlist = AudioPlaylist.find(params[:playlist_id])
    track_ids = params[:track_ids]

    if track_ids.present?
      track_ids.each do |track_id|
        @audio_playlist_track_position = AudioPlaylistTrack.where('audio_playlist_id = ?', params[:playlist_id])
        .order('position ASC')
        .find(:last)
        @audio_playlist_track_position = @audio_playlist_track_position.nil? ? 1 : @audio_playlist_track_position.position + 1
        @audio_playlist_track = AudioPlaylistTrack.new(audio_playlist_id: params[:playlist_id],
                                                       track_id: track_id,
                                                       position: @audio_playlist_track_position)

        @track_to_add = Track.find(track_id)

        #check if track has been added to a previous playlist before
        @playlists_with_track = AudioPlaylistTrack.where("track_id = ?", track_id)
        .group("audio_playlist_id")

        if !@playlists_with_track.empty?
          @playlists = []
          @playlists_with_track.each do |playlist_item|
            @notice = "#{@track_to_add.title_original.to_s} (#{@track_to_add.id.to_s}) exists in playlists: "
            if !playlist_item.audio_playlist.nil?
              @playlists << "<a href='/audio_playlists/#{playlist_item.audio_playlist_id.to_s}' target='_blank' class='alert-link'>#{playlist_item.audio_playlist_id.to_s} (#{playlist_item.audio_playlist.client_playlist_code.to_s})</a>"
            end
          end
          @notice += @playlists.join(', ')
          @notice_array << @notice
          @tracks_to_add << track_id
        else
          if @audio_playlist_track.save
            flash[:notice] = 'Tracks were successfully added to playlist.'
            @notice = "#{@track_to_add.title_original.to_s} (#{@track_to_add.id.to_s}) was added to playlist."
            @notice_array << @notice
            session[:audios_search] = collection_to_id_array(@audio_playlist.tracks)
          end
        end

      end # loop through audio ids
    end

  end

  def export_to_excel
    @audio_playlist = AudioPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Airline Code",
                   "Airline Name",
                   "Playdate Start Month",
                   "Playdate Start Year",
                   "Playdate End Month",
                   "Playdate End Year",
                   "VO",
                   "Total Duration",
                   "Airline Duration"]

    # header row

    if @audio_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @audio_playlist.airline.code
      airline_name = @audio_playlist.airline.name
    end
    vo = @audio_playlist.vo.name if !@audio_playlist.vo_id.nil?
    sheet.add_row [airline_code,
                   airline_name,
                   @audio_playlist.start_playdate.strftime("%B"),
                   @audio_playlist.start_playdate.strftime("%Y"),
                   @audio_playlist.end_playdate.strftime("%B"),
                   @audio_playlist.end_playdate.strftime("%Y"),
                   vo,
                   @audio_playlist.total_duration_cached,
                   @audio_playlist.airline_duration]

    sheet.add_lines(1)

    # header row
    sheet.add_row ["Mastering",
                   "Song Order",
                   "Title (Translated)",
                   "Title (Original)",

                   "Artist (Translated)",
                   "Artist (Original)",
                   "Label",
                   "Origin",
                   "Composer",
                   "Duration",

                   "Split (min)",
                   "VO Duration (sec)",
                   "Accumulated Duration"]

    accum_duration = 0
    # data rows
    @audio_playlist.audio_playlist_tracks_sorted.each.with_index do |audio_playlist_track, index|
      if !audio_playlist_track.track.album.label_id.nil?
        label = audio_playlist_track.track.album.label.name
      else
        label =""
      end

      if !audio_playlist_track.track.origin_id.nil? && audio_playlist_track.track.origin_id!=0
        origin = audio_playlist_track.track.origin.name
      else
        origin =""
      end

      if audio_playlist_track.vo_duration.nil?
        vo_duration=0
      else
        vo_duration = audio_playlist_track.vo_duration.to_i
      end

      split = ""
      split = "#{audio_playlist_track.split} min" if !audio_playlist_track.split.nil? && audio_playlist_track.split!=0 && audio_playlist_track.split!=""

      sheet.add_row [audio_playlist_track.mastering,

                     index + 1,

                     audio_playlist_track.track.title_english,

                     audio_playlist_track.track.title_original,

                     audio_playlist_track.track.artist_english,

                     audio_playlist_track.track.artist_original,

                     label,

                     origin,

                     audio_playlist_track.track.composer,

                     audio_playlist_track.track.duration_in_min,

                     split,

                     audio_playlist_track.vo_duration,

                     duration(accum_duration + audio_playlist_track.track.duration)]

      if !audio_playlist_track.split.nil? && audio_playlist_track.split!=0
        accum_duration = 0
      else
        accum_duration += audio_playlist_track.track.duration + (vo_duration*1000)
      end

    end

    # send it to the browsah
    data = StringIO.new ''
    book.write data
    send_data data.string,
              type: "application/excel",
              disposition: 'attachment',
              filename: 'audio_playlist.xls'
  end

  def splits
    @splits = Split.order(:duration)
    render layout: false
  end

  def download_audio_playlist
    # Set up XMLRPC Client. Server located at https://imagesinmotion.no-ip.biz/server/audio_file_operations.php
    app_id = Settings.iim_app_id
    nas_url = Settings.nas_url

    client = XMLRPC::Client.new_from_uri(nas_url)

    client.disableSSLVerification()
    client.http_header_extra = {'Content-Type' => 'text/xml'}
    client.timeout = nil

    # Reset DB
    @audio_playlist = AudioPlaylist.find(params[:id])
    @audio_playlist.update_attributes job_current_progress: nil,
                                      job_current_track: nil,
                                      job_id: nil,
                                      job_finished_at: nil,
                                      job_total_tracks: nil

    # Gather data
    @tracks_found = @audio_playlist.audio_playlist_tracks_sorted.delete_if { |playlist_track| !playlist_track.track.mp3_exists }

    @albums = @tracks_found.map { |t| t.track.album_id }.flatten
    @tracks = @tracks_found.map { |t| t.track.track_num }.flatten
    @track_positions = @tracks_found.map { |t| t.position.to_s }.flatten

    # Call
    begin
      result = client.call2('create_tracks_zip', app_id, params[:id], @albums, @tracks, @track_positions)
    rescue Timeout::Error => e
      flash[:notice] = 'Could not connect to NAS'
    end

    # Callback
    if result
      puts result
      flash[:notice] = 'Zip file created successfully.'
      @audio_playlist.update_attribute :job_finished_at, Time.current
      respond_to do |format|
        format.js
      end
    end
  end

  def delete_audio_playlist_zip
    # Set up XMLRPC Client. Server located at https://imagesinmotion.no-ip.biz/server/audio_file_operations.php
    app_id = Settings.iim_app_id
    nas_url = Settings.nas_url

    client = XMLRPC::Client.new_from_uri(nas_url)

    client.disableSSLVerification()
    client.http_header_extra = {'Content-Type' => 'text/xml'}
    client.timeout = nil

    # Reset DB
    @audio_playlist = AudioPlaylist.find(params[:id])
    @audio_playlist.update_attributes job_current_progress: nil,
                                      job_current_track: nil,
                                      job_id: nil,
                                      job_finished_at: nil,
                                      job_total_tracks: nil

    # Call
    begin
      result = client.call2('delete_tracks_zip', app_id, params[:id])
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
    puts session[:audio_playlist_checked] = params[:checked]
    render nothing: true
  end

  def sort_alphabetically
    @audio_playlist = AudioPlaylist.find(params[:id])
    @audio_playlist_tracks = @audio_playlist.audio_playlist_tracks

    puts params[:sort]

    if params[:sort] == 'title'
      @audio_playlist_tracks.sort_by! { |m| m.track.title_original.downcase }.each.with_index do |t, index|
        t.update_attribute :position_position, index
      end
    elsif params[:sort] == 'artist'
      @audio_playlist_tracks.sort_by! { |m| [m.track.artist_original.downcase, m.track.title_original.downcase] }.each.with_index do |t, index|
        t.update_attribute :position_position, index
      end
    end

    redirect_to :back
  end

  private

  def get_columns
    @columns = ['#', 'Title', 'Intro Tempo', 'Composer', 'Label', 'Track Title (Translated)', 'Tempo', 'Track Num', 'Origin', 'Artist', 'Outro Tempo', 'Duration', 'CD Code', 'Mastering', 'Split', 'VO Duration (sec)', 'Genre', 'Accumulated Duration']
  end

end
