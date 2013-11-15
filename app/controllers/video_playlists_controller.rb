# encoding: utf-8
require "spreadsheet"
require 'stringio'

class VideoPlaylistsController < ApplicationController
  layout "layouts/application",
         except: :export
  before_filter :require_user
  filter_access_to :all

  def index
    @search = VideoPlaylist.includes(:airline, :video_playlist_type)
    .ransack(view_context.empty_blank_params params[:q])
    @video_playlists = @search.result(distinct: true)
    .order("video_playlists.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page)

    @video_playlists_count = @video_playlists.count
  end

  def new
    @video_playlist = VideoPlaylist.new
  end

  def create

    @video_playlist = VideoPlaylist.new(params[:video_playlist])
    @video_playlist.user_id = current_user.id
    @video_playlist.locked = false

    respond_to do |format|
      if @video_playlist.save
        flash[:notice] = 'Playlist was successfully created.'

        format.html { redirect_to(edit_video_playlist_path(@video_playlist)) }

      else
        format.html { render action: "new" }

      end
    end
  end

  def edit
    @search = VideoPlaylist.includes(:airline, :video_playlist_type)
    .ransack(view_context.empty_blank_params params[:q])
    @video_playlists = @search.result(distinct: true)
    .order("video_playlists.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page)

    @video_playlists_count = @video_playlists.count

    @video_playlist = VideoPlaylist.find(params[:id], include: [:video_playlist_items, :videos])
    session[:videos_search] = collection_to_id_array(@video_playlist.videos)
  end

  def update
    @video_playlist = VideoPlaylist.find(params[:id])

    respond_to do |format|
      if @video_playlist.update_attributes(params[:video_playlist])
        flash[:notice] = 'Playlist was successfully updated.'
        format.html { redirect_to(:back) }

      else
        format.html { render action: "edit" }

      end
    end
  end

  def show
    @video_playlist = VideoPlaylist.includes(video_playlist_items: :video)
    .find(params[:id])
  end

  def show_chinese
    @video_playlist = VideoPlaylist.includes(video_playlist_items: :video)
    .find(params[:id])
  end

  #display overlay
  def add_video_to_playlist

    @video_playlist = VideoPlaylist.find(params[:id])
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    @search = Video.ransack(view_context.empty_blank_params params[:q])
    @videos = @search.result(distinct: true)
    .where("to_delete = ?", "0")
    .order("videos.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page)

    if params[:language].present?
      @videos = @videos.with_language_track(params[:language][:track]) if params[:language][:track].present?
      @videos = @videos.with_language_subtitle(params[:language][:subtitle]) if params[:language][:subtitle].present?
    end

    @videos_count = @videos.count
    session[:videos_search] = collection_to_id_array(@videos)

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  #add video to playlist
  def add_video

    @video_playlist = VideoPlaylist.find(params[:id])

    @video_playlist_item_position = VideoPlaylistItem.where("video_playlist_id=?", params[:id])
                                                     .order("position ASC")
                                                     .find(:last)
    @video_playlist_item_position = @video_playlist_item_position.nil? ? 1 : @video_playlist_item_position.position + 1

    @video_playlist_item = VideoPlaylistItem.new(video_playlist_id: params[:id],
                                                 video_id: params[:video_id],
                                                 position: @video_playlist_item_position)

    @notice=""
    @video_to_add = Video.find(params[:video_id])

    if @video_playlist_item.save
      flash[:notice] = 'Video was successfully added.'
      session[:videos_search] = collection_to_id_array(@video_playlist.videos)
    end
  end

  #add selected videos to playlist
  def add_multiple_videos

    @notice = ""
    @video_playlist = VideoPlaylist.find(params[:playlist_id])
    video_ids = params[:video_ids]

    video_ids.each do |video_id|
      @video_playlist_item_position = VideoPlaylistItem.where("video_playlist_id=?", params[:playlist_id])
                                                       .order("position ASC")
                                                       .find(:last)
      @video_playlist_item_position = @video_playlist_item_position.nil? ? 1 : @video_playlist_item_position.position + 1
      @video_playlist_item = VideoPlaylistItem.new(video_playlist_id: params[:playlist_id],
                                                   video_id: video_id,
                                                   position: @video_playlist_item_position)

      @video_to_add = Video.find(video_id)
      if @video_playlist_item.save
        flash[:notice] = 'Videos were successfully added.'
        session[:videos_search] = collection_to_id_array(@video_playlist.videos)
      end
    end # loop through video ids

  end

  def destroy
    @video_playlist = VideoPlaylist.find(params[:id])
    @video_playlist.destroy

    respond_to do |format|
      format.html { redirect_to(video_playlists_path) }
      format.js
    end
  end

  def duplicate

    @playlist = VideoPlaylist.find(params[:id])
    @playlist_duplicate = VideoPlaylist.create(
        start_cycle: @playlist.start_cycle,
        end_cycle: @playlist.end_cycle,
        user_id: current_user.id
    )

    @video_playlist_items = VideoPlaylistItem.where("video_playlist_id=#{@playlist.id}").order("position ASC")

    @video_playlist_items.each do |item|

      VideoPlaylistItem.create(
          video_id: item.video_id,
          position: item.position,
          video_playlist_id: @playlist_duplicate.id
      )

    end

    respond_to do |format|
      format.html { redirect_to(edit_video_playlist_path(@playlist_duplicate)) }
    end
  end

  def lock
    @video_playlist = VideoPlaylist.find(params[:id])
    @video_playlist.locked = true
    @video_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was locked'
      format.html { redirect_to(video_playlists_path) }
    end
  end

  def unlock
    @video_playlist = VideoPlaylist.find(params[:id])
    @video_playlist.locked = false
    @video_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was unlocked'
      format.html { redirect_to(video_playlists_path) }
    end
  end

  #def print
  #
  #  @video_playlist = VideoPlaylist.find(params[:id])
  #
  #  if @video_playlist.video_playlist_type.nil?
  #    video_type = " "
  #  else
  #    video_type = " " + @video_playlist.video_playlist_type.name
  #  end
  #
  #  headers["Content-Disposition"] = "attachment; filename=\"#{@video_playlist.airline.code if !@video_playlist
  #   .airline.nil? }#{@video_playlist.start_cycle.strftime("%m%y")}#{video_type}.pdf\""
  #
  #  respond_to do |format|
  #    format.html
  #    format.pdf {
  #      render text: PDFKit.new(print_video_playlist_url(@video_playlist)).to_pdf,
  #             layout: false
  #    }
  #  end
  #end


  def export_to_excel
    @video_playlist = VideoPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Airline Name",
                   "Start Cycle",
                   "End Cycle"]

    if @video_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @video_playlist.airline.code
      airline_name = @video_playlist.airline.name
    end

    sheet.add_row [airline_code,
                   airline_name,
                   @video_playlist.start_cycle.strftime("%B"),
                   @video_playlist.start_cycle.strftime("%Y"),
                   @video_playlist.end_cycle.strftime("%B"),
                   @video_playlist.end_cycle.strftime("%Y")]

    sheet.add_lines(1)

    video_playlist_items = @video_playlist.video_playlist_items_sorted

    # Video Playlist Summary
    # header row
    sheet.add_row ["Position",
                   "Programme Title",
                   "Chinese Programme Title",
                   "Distributor",
                   "Genre",
                   "Commercial Run Time",
                   "Lang Tracks",
                   "Lang Subtitles",
                   "Synopsis",
                   "Chinese Synopsis",
                   "Poster"]

    # data rows
    video_playlist_items.each.with_index do |video_playlist_item, index|

      if video_playlist_item.video.video_distributor.nil?
        video_distributor = ""
      else
        video_distributor = video_playlist_item.video.video_distributor.company_name
      end

      if video_playlist_item.video.commercial_run_time.nil?
        runtime = ""
      else
        runtime = video_playlist_item.video.commercial_run_time.minutes
      end

      sheet.add_row [index + 1,

                     video_playlist_item.video.programme_title,
                     video_playlist_item.video.chinese_programme_title,

                     video_distributor,

                     video_playlist_item.video.video_genres_string_with_parent,

                     runtime,
                     (video_playlist_item.video.language_tracks.nil? ? "" : video_playlist_item.video.language_tracks.join(',
')),

                     (video_playlist_item.video.language_subtitles.nil? ? "" : video_playlist_item.video.language_subtitles.join(',
')),

                     video_playlist_item.video.synopsis,
                     video_playlist_item.video.chinese_synopsis,

                     "http://hub.iim.com.sg" + video_playlist_item.video.poster.url]
    end

    sheet.add_lines(1)

    if @video_playlist.video_playlist_type.nil?
      video_type = " "
    else
      video_type = " " + @video_playlist.video_playlist_type.name
    end

    data = StringIO.new ''
    book.write data
    send_data data.string,
              type: "application/excel",
              disposition: 'attachment',
              filename: "#{airline_code}#{@video_playlist.start_cycle.strftime("%m%y")}#{video_type}.xls"
  end

  def sort
    params[:videoplaylist].each_with_index do |id,
        pos|
      VideoPlaylistItem.find(id).update_attribute(:position,
                                                  pos+1)
    end
    render nothing: true
  end
end