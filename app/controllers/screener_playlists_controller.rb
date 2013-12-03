# encoding: utf-8
require "spreadsheet"
require 'stringio'

class ScreenerPlaylistsController < ApplicationController
=begin
  in_place_edit_for :screener_playlist_item,
                    :mastering
=end

  layout "layouts/application",
         except: :export
  before_filter :require_user
  before_filter :get_columns
  filter_access_to :all


  def index
    @search = ScreenerPlaylist.includes(:airline, :video_playlist_type)
                              .ransack(view_context.empty_blank_params params[:q])
    @screener_playlists = @search.result(distinct: true)
                                 .order("screener_playlists.id DESC")
                                 .paginate(page: params[:page],
                                           per_page: items_per_page)

    @screener_playlists_count = @screener_playlists.count
  end

  def new
    @screener_playlist = ScreenerPlaylist.new
  end

  def create

    @screener_playlist = ScreenerPlaylist.new(params[:screener_playlist])
    @screener_playlist.user_id = current_user.id
    @screener_playlist.locked = false;

    respond_to do |format|
      if @screener_playlist.save
        flash[:notice] = 'Playlist was successfully created.'

        format.html { redirect_to(edit_screener_playlist_path(@screener_playlist)) }

      else
        format.html { render action: "new" }

      end
    end
  end

  def edit

    @search = ScreenerPlaylist.includes(:airline, :video_playlist_type)
                              .ransack(view_context.empty_blank_params params[:q])
    @screener_playlists = @search.result(distinct: true)
                                 .order("screener_playlists.id DESC")
                                 .paginate(page: params[:page],
                                           per_page: items_per_page)

    @screener_playlist = ScreenerPlaylist.includes(screener_playlist_items: :screener)
                                         .find(params[:id])
    session[:screeners_search] = collection_to_id_array(@screener_playlist.screeners)
  end

  def update
    @screener_playlist = ScreenerPlaylist.find(params[:id])

    respond_to do |format|
      if @screener_playlist.update_attributes(params[:screener_playlist])
        flash[:notice] = 'Playlist was successfully updated.'
        format.html { redirect_to(:back) }

      else
        format.html { render action: "edit" }

      end
    end
  end

  def show
    @screener_playlist = ScreenerPlaylist.includes(screener_playlist_items: :screener)
    .find(params[:id])
  end

  def show_chinese
    @screener_playlist = ScreenerPlaylist.includes(screener_playlist_items: :screener)
    .find(params[:id])
  end

  #display overlay
  def add_screener_to_playlist

    @screener_playlist = ScreenerPlaylist.find(params[:id])
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    @search = Screener.ransack(view_context.empty_blank_params params[:q])
    @screeners = @search.result(distinct: true)
    .order("screeners.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page)

    if params[:language].present?
      @screeners = @screeners.with_language_track(params[:language][:track]) if params[:language][:track].present?
      @screeners = @screeners.with_language_subtitle(params[:language][:subtitle]) if params[:language][:subtitle].present?
    end

    @screeners_count = @screeners.count

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  #add screener to playlist
  def add_screener

    @screener_playlist = ScreenerPlaylist.find(params[:id])
    @screener_playlist_item_position = ScreenerPlaylistItem.where("screener_playlist_id=?", params[:id])
    .order("position ASC")
    .find(:last)
    @screener_playlist_item_position = @screener_playlist_item_position.nil? ? 1 : @screener_playlist_item_position.position + 1
    @screener_playlist_item = ScreenerPlaylistItem.new(screener_playlist_id: params[:id],
                                                       screener_id: params[:screener_id],
                                                       position: @screener_playlist_item_position)

    @notice=""

    @screener_to_add = Screener.find(params[:screener_id])

    if @screener_playlist_item.save
      flash[:notice] = 'Screener was successfully added.'
      session[:screeners_search] = collection_to_id_array(@screener_playlist.screeners)
    end
  end

  #add selected videos to playlist
  def add_multiple_screeners

    @notice = ""
    @screener_playlist = ScreenerPlaylist.find(params[:playlist_id])
    screener_ids = params[:screener_ids]

    screener_ids.each do |screener_id|
      @screener_playlist_item_position = ScreenerPlaylistItem.where("screener_playlist_id=?", params[:playlist_id])
      .order("position ASC")
      .find(:last)
      @screener_playlist_item_position = @screener_playlist_item_position.nil? ? 1 : @screener_playlist_item_position.position + 1
      @screener_playlist_item = ScreenerPlaylistItem.new(screener_playlist_id: params[:playlist_id],
                                                         screener_id: screener_id,
                                                         position: @screener_playlist_item_position)

      @screener_to_add = Screener.find(screener_id)
      if @screener_playlist_item.save
        flash[:notice] = 'Screeners were successfully added.'
        session[:screeners_search] = collection_to_id_array(@screener_playlist.screeners)
      end
    end # loop through video ids

  end

  def destroy
    @screener_playlist = ScreenerPlaylist.find(params[:id])
    @screener_playlist.destroy

    respond_to do |format|
      format.html { redirect_to(screener_playlists_path) }
      format.js
    end
  end

  def lock
    @screener_playlist = ScreenerPlaylist.find(params[:id])
    @screener_playlist.locked = true
    @screener_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was locked'
      format.html { redirect_to(screener_playlists_path) }
    end
  end

  def unlock
    @screener_playlist = ScreenerPlaylist.find(params[:id])
    @screener_playlist.locked = false
    @screener_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was unlocked'
      format.html { redirect_to(screener_playlists_path) }
    end
  end

  #def print
  #
  #  @screener_playlist = ScreenerPlaylist.find(params[:id])
  #  if @screener_playlist.video_playlist_type.nil?
  #    video_type = " "
  #  else
  #    video_type = " " + @screener_playlist.video_playlist_type.name
  #  end
  #  headers["Content-Disposition"] = "attachment; filename=\"#{@screener_playlist.airline.code if
  #   !@screener_playlist.airline.nil? }#{@screener_playlist.start_cycle.strftime("%m%y")}#{video_type} Screener.pdf\""
  #
  #  respond_to do |format|
  #    format.html
  #    format.pdf {
  #      render text: PDFKit.new(print_video_playlist_url(@screener_playlist)).to_pdf,
  #             layout: false
  #    }
  #  end
  #
  #end


  def export_to_excel
    @screener_playlist = ScreenerPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Airline Name",
                   "Start Cycle",
                   "End Cycle"]

    if @screener_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @screener_playlist.airline.code
      airline_name = @screener_playlist.airline.name
    end

    sheet.add_row [airline_code,
                   airline_name,
                   @screener_playlist.start_cycle.strftime("%B"),
                   @screener_playlist.start_cycle.strftime("%Y"),
                   @screener_playlist.end_cycle.strftime("%B"),
                   @screener_playlist.end_cycle.strftime("%Y")]

    sheet.add_lines(1)

    screener_playlist_items = @screener_playlist.screener_playlist_items_sorted

    # Screener Playlist Summary
    # header row
    sheet.add_row ["Position",
                   "Video Title",
                   "Chinese Video Title",
                   "Episode Title",
                   "Episode Number",
                   "Distributor",
                   "Location",
                   "Full Genre",
                   "Commercial Runtime",
                   "Lang Tracks",
                   "Lang Subtitles",
                   "Chinese Synopsis",
                   "Synopsis"]

    # data rows
    screener_playlist_items.each.with_index do |screener_playlist_item, index|

      if screener_playlist_item.screener.video.video_distributor.nil?
        distributor = ""
      else
        distributor = screener_playlist_item.screener.video.video_distributor
      end

      sheet.add_row [index + 1,

                     screener_playlist_item.screener.video.programme_title,
                     screener_playlist_item.screener.video.chinese_programme_title,

                     screener_playlist_item.screener.episode_title,

                     screener_playlist_item.screener.episode_number,

                     distributor,
                     screener_playlist_item.screener.location,
                     screener_playlist_item.screener.video.video_genres_string_with_parent,
                     (screener_playlist_item.screener.video.commercial_run_time.nil? ? "" : screener_playlist_item.screener.video.commercial_run_time.minutes),

                     (screener_playlist_item.screener.video.language_tracks.nil? ? "" : screener_playlist_item.screener.video.language_tracks.join(',
')),
                     (screener_playlist_item.screener.video.language_subtitles.nil? ? "" : screener_playlist_item.screener.video.language_subtitles.join(',
')),
                     screener_playlist_item.screener.video.synopsis,
                     screener_playlist_item.screener.video.chinese_synopsis
                    ]
    end

    sheet.add_lines(1)

    if @screener_playlist.video_playlist_type.nil?
      video_type = " "
    else
      video_type = " " + @screener_playlist.video_playlist_type.name
    end

    data = StringIO.new ''
    book.write data
    send_data data.string,
              type: "application/excel",
              disposition: 'attachment',
              filename: "#{airline_code}#{@screener_playlist.start_cycle.strftime("%m%y")}#{video_type} Screener.xls"
  end

  def sort
    params[:videoplaylist].each_with_index do |id,
        pos|
      ScreenerPlaylistItem.find(id).update_attribute(:position,
                                                     pos+1)
    end
    render nothing: true
  end


  def duplicate

    @playlist = ScreenerPlaylist.find(params[:id])
    @playlist_duplicate = ScreenerPlaylist.create(
        start_cycle: @playlist.start_cycle,
        end_cycle: @playlist.end_cycle,
        user_id: current_user.id,
        media_instruction: @playlist.media_instruction
    )
    @screener_playlist_items = ScreenerPlaylistItem.where("screener_playlist_id=#{@playlist.id}")
    .order("position ASC")

    @screener_playlist_items.each do |item|

      ScreenerPlaylistItem.create(
          screener_id: item.screener_id,
          position: item.position,
          mastering: item.mastering,
          screener_playlist_id: @playlist_duplicate.id
      )

    end

    respond_to do |format|
      format.html { redirect_to(edit_screener_playlist_path(@playlist_duplicate)) }
    end
  end

  def table_column_select
    puts session[:screener_playlist_checked] = params[:checked]
    render nothing: true
  end

  private

  def get_columns
    @columns = ['#', 'Programme Title', '(Chinese)', 'Episode Title', 'Episode Number', 'Distributor', 'Location', 'Remarks', 'Other']
  end

end