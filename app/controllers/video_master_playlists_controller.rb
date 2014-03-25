# encoding: utf-8
require "spreadsheet"
require 'stringio'

class VideoMasterPlaylistsController < ApplicationController
=begin
  in_place_edit_for :video_master_playlist_item,
                    :mastering
=end

  layout "layouts/application",
         except: :export
  before_filter :require_user
  before_filter :get_columns
  filter_access_to :all


  def index
    @search = VideoMasterPlaylist.includes(:airline, :master_playlist_type)
    .ransack(view_context.empty_blank_params params[:q])
    @video_master_playlists = @search.result(distinct: true)
    .order("video_master_playlists.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    @video_master_playlists_count = @video_master_playlists.count
  end

  def new
    @video_master_playlist = VideoMasterPlaylist.new
  end

  def create

    @video_master_playlist = VideoMasterPlaylist.new(params[:video_master_playlist])
    @video_master_playlist.user_id = current_user.id
    @video_master_playlist.locked = false;

    respond_to do |format|
      if @video_master_playlist.save
        flash[:notice] = 'Playlist was successfully created.'

        format.html { redirect_to(edit_video_master_playlist_path(@video_master_playlist)) }

      else
        format.html { render action: "new" }
        format.json { render json: @video_master_playlist.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit

    @search = VideoMasterPlaylist.includes(:airline, :master_playlist_type)
    .ransack(view_context.empty_blank_params params[:q])
    @video_master_playlists = @search.result(distinct: true)
    .order("video_master_playlists.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    @video_master_playlist = VideoMasterPlaylist.includes(video_master_playlist_items: :master)
    .find(params[:id])
    session[:masters_search] = collection_to_id_array(@video_master_playlist.masters)
  end

  def update
    @video_master_playlist = VideoMasterPlaylist.find(params[:id])

    respond_to do |format|
      if @video_master_playlist.update_attributes(params[:video_master_playlist])
        flash[:notice] = 'Playlist was successfully updated.'
        format.html { redirect_to(:back) }
        format.json { respond_with_bip(@video_master_playlist) }
      else
        format.html { render action: "edit" }
        format.json { respond_with_bip(@video_master_playlist) }
      end
    end
  end

  def show
    @video_master_playlist = VideoMasterPlaylist.includes(video_master_playlist_items: :master)
    .find(params[:id])
  end

  def show_chinese
    @video_master_playlist = VideoMasterPlaylist.includes(video_master_playlist_items: :master)
    .find(params[:id])
  end

  #display overlay
  def add_video_master_to_playlist

    @video_master_playlist = VideoMasterPlaylist.find(params[:id])
    @languages = MasterLanguage.order("name")
    .collect { |language| language.name }

    if params[:q].present?
      @original = params[:q][:video_programme_title_or_video_foreign_language_title_or_video_chinese_programme_title_cont_any]
      @the = params[:q][:video_programme_title_or_video_foreign_language_title_or_video_chinese_programme_title_cont_any][0..3].downcase if params[:q][:video_programme_title_or_video_foreign_language_title_or_video_chinese_programme_title_cont_any].present?
      if @the == 'the ' && params[:q][:video_programme_title_or_video_foreign_language_title_or_video_chinese_programme_title_cont_any].present?
        @title = params[:q][:video_programme_title_or_video_foreign_language_title_or_video_chinese_programme_title_cont_any][4..-1].downcase
        params[:q][:video_programme_title_or_video_foreign_language_title_or_video_chinese_programme_title_cont_any] = ["#{@original}", "#{@title}, the"]
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

    @search = Master.ransack(view_context.empty_blank_params params[:q])
    @masters = @search.result(distinct: true)
    .order("masters.id DESC")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    if params[:language].present?
      @masters = @masters.with_language_track(params[:language][:track]) if params[:language][:track].present?
      @masters = @masters.with_language_subtitle(params[:language][:subtitle]) if params[:language][:subtitle].present?
    end

    @masters_count = @masters.count

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  #add master to playlist
  def add_video_master

    @video_master_playlist = VideoMasterPlaylist.find(params[:id])
    @video_master_playlist_item_position = VideoMasterPlaylistItem.where("video_master_playlist_id=?", params[:id])
    .order("position ASC")
    .find(:last)
    @video_master_playlist_item_position = @video_master_playlist_item_position.nil? ? 1 : @video_master_playlist_item_position.position + 1
    @video_master_playlist_item = VideoMasterPlaylistItem.new(video_master_playlist_id: params[:id],
                                                              master_id: params[:master_id],
                                                              position: @video_master_playlist_item_position)

    @notice=""

    @master_to_add = Master.find(params[:master_id])

    if @video_master_playlist_item.save
      flash[:notice] = 'Master was successfully added.'
      session[:masters_search] = collection_to_id_array(@video_master_playlist.masters)
    end
  end

  #add selected videos to playlist
  def add_multiple_masters

    @notice = ""
    @video_master_playlist = VideoMasterPlaylist.find(params[:playlist_id])
    master_ids = params[:master_ids]

    master_ids.each do |master_id|
      @video_master_playlist_item_position = VideoMasterPlaylistItem.where("video_master_playlist_id=?", params[:playlist_id])
      .order("position ASC")
      .find(:last)
      @video_master_playlist_item_position = @video_master_playlist_item_position.nil? ? 1 : @video_master_playlist_item_position.position + 1
      @video_master_playlist_item = VideoMasterPlaylistItem.new(video_master_playlist_id: params[:playlist_id],
                                                                master_id: master_id,
                                                                position: @video_master_playlist_item_position)

      @master_to_add = Master.find(master_id)
      if @video_master_playlist_item.save
        flash[:notice] = 'Masters were successfully added.'
        session[:masters_search] = collection_to_id_array(@video_master_playlist.masters)
      end
    end # loop through video ids

  end

  def destroy
    @video_master_playlist = VideoMasterPlaylist.find(params[:id])
    @video_master_playlist.destroy

    respond_to do |format|
      format.html { redirect_to(video_master_playlists_path) }
      format.js
    end
  end

  def lock
    @video_master_playlist = VideoMasterPlaylist.find(params[:id])
    @video_master_playlist.locked = true
    @video_master_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was locked'
      format.html { redirect_to(video_master_playlists_path) }
    end
  end

  def unlock
    @video_master_playlist = VideoMasterPlaylist.find(params[:id])
    @video_master_playlist.locked = false
    @video_master_playlist.save

    respond_to do |format|
      flash[:notice] = 'Playlist was unlocked'
      format.html { redirect_to(video_master_playlists_path) }
    end
  end

  #def print
  #
  #  @video_master_playlist = VideoMasterPlaylist.find(params[:id])
  #  if @video_master_playlist.master_playlist_type.nil?
  #    video_type = " "
  #  else
  #    video_type = " " + @video_master_playlist.master_playlist_type.name
  #  end
  #  headers["Content-Disposition"] = "attachment; filename=\"#{@video_master_playlist.airline.code if
  #   !@video_master_playlist.airline.nil? }#{@video_master_playlist.start_cycle.strftime("%m%y")}#{video_type} Master.pdf\""
  #
  #  respond_to do |format|
  #    format.html
  #    format.pdf {
  #      render text: PDFKit.new(print_video_playlist_url(@video_master_playlist)).to_pdf,
  #             layout: false
  #    }
  #  end
  #
  #end

  def export_to_excel
    @video_master_playlist = VideoMasterPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet name: 'Video Master Playlist'
    sheet1.row(0).replace ['Airline Name',
                           'Start Cycle',
                           'End Cycle']

    if @video_master_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @video_master_playlist.airline.code
      airline_name = @video_master_playlist.airline.name
    end

    sheet1.row(1).replace [airline_code,
                           airline_name,
                           @video_master_playlist.start_cycle.strftime('%B'),
                           @video_master_playlist.start_cycle.strftime('%Y'),
                           @video_master_playlist.end_cycle.strftime('%B'),
                           @video_master_playlist.end_cycle.strftime('%Y')]

    sheet1.row(3).replace ["Media Instruction"]
    sheet1.row(4).replace [@video_master_playlist.media_instruction]

    video_master_playlist_items = @video_master_playlist.video_master_playlist_items_sorted

    # Master Playlist Summary
    # header row
    sheet1.row(6).replace ['Position',
                           'Programme Title',
                           'Chinese Programme Title',
                           'Episode Title',
                           'Episode Number',
                           'Distributor',
                           'Tape Media',
                           'Tape Format',
                           'Tape Size',
                           'Aspect Ratio',
                           'Language Track 1',
                           'Language Track 2',
                           'Language Track 3',
                           'Language Track 4',
                           'Video Subtitles 1',
                           'Video Subtitles 2',
                           'Master Tape Location',
                           'Master Time In',
                           'Master Time Out',
                           'Duration',
                           'Programme Synopsis',
                           'Chinese Programme Synopsis',
                           'Episode Synopsis',
                           'Genre, Sub-Genre',
                           'Mastering']

    # data rows
    video_master_playlist_items.each.with_index do |video_master_playlist_item, index|

      if video_master_playlist_item.master.video.video_distributor.nil?
        distributor = ""
      else
        distributor = video_master_playlist_item.master.video.video_distributor.company_name
      end

      if video_master_playlist_item.master.present?
        sheet1.row(index + 7).replace [index + 1,
                                       video_master_playlist_item.master.video.programme_title,
                                       video_master_playlist_item.master.video.chinese_programme_title,
                                       video_master_playlist_item.master.episode_title,
                                       video_master_playlist_item.master.episode_number,
                                       distributor,
                                       video_master_playlist_item.master.tape_media,
                                       video_master_playlist_item.master.tape_format,
                                       video_master_playlist_item.master.tape_size,
                                       video_master_playlist_item.master.aspect_ratio,
                                       video_master_playlist_item.master.language_track_1,
                                       video_master_playlist_item.master.language_track_2,
                                       video_master_playlist_item.master.language_track_3,
                                       video_master_playlist_item.master.language_track_4,
                                       video_master_playlist_item.master.video_subtitles_1,
                                       video_master_playlist_item.master.video_subtitles_2,
                                       video_master_playlist_item.master.location,
                                       video_master_playlist_item.master.time_in,
                                       video_master_playlist_item.master.time_out,
                                       video_master_playlist_item.master.duration,
                                       video_master_playlist_item.master.video.synopsis,
                                       video_master_playlist_item.master.video.chinese_synopsis,
                                       video_master_playlist_item.master.synopsis,
                                       video_master_playlist_item.master.video.video_genres_string_with_parent,
                                       video_master_playlist_item.mastering,
                                      ]
      end
    end

    sheet2 = book.create_worksheet name: 'Video Master Playlist Formatted'

    # Header row
    format = Spreadsheet::Format.new color: :white, pattern_fg_color: :blue, pattern: 1, weight: :bold, size: 10,
                                     align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
    sheet2.row(0).default_format = format
    sheet2.row(0).height = 36
    headers = ['A/L',
               'CYCLE START',
               'CYCLE END',
               'PO#',
               'TITLE',
               'EPISODE',
               'EPS #',
               'DIST',
               'R/T MINS',
               'AUDIO 1',
               'AUDIO 2',
               'SUBS',
               'LICENSE FEE',
               'MATERIAL COST',
               'PO STATUS',
               'MASTER STATUS',
               'FILE STATUS',
               'SUBTITLE CREATION STATUS',
               'NEW',
               'HOLDOVER',
               'SYNOPSIS']
    sheet2.row(0).replace headers

    if @video_master_playlist.airline_id.nil?
      airline_code = ''
    else
      airline_code = @video_master_playlist.airline.code
    end

    # data rows
    video_master_playlist_items = @video_master_playlist.video_master_playlist_items_sorted
    video_master_playlist_items.each.with_index do |video_master_playlist_item, index|

      if video_master_playlist_item.master.video.video_distributor.nil?
        distributor = ''
      else
        distributor = video_master_playlist_item.master.video.video_distributor.company_name
      end

      if video_master_playlist_item.master.location.nil?
        master_status = 'Pending'
      else
        master_status = 'In'
      end

      if video_master_playlist_item.master.video_subtitles_1 == ''
        subtitle_creation_status = 'NA'
      else
        subtitle_creation_status = "ENCODE WITH #{video_master_playlist_item.master.video_subtitles_1} SUBS"
      end

      entry = [airline_code,
               @video_master_playlist.start_cycle.strftime("%m%y"),
               @video_master_playlist.end_cycle.strftime("%m%y"),
               '',
               video_master_playlist_item.master.video.programme_title.upcase,
               video_master_playlist_item.master.episode_title.upcase,
               video_master_playlist_item.master.episode_number.upcase,
               distributor.upcase,
               video_master_playlist_item.master.duration.upcase,
               video_master_playlist_item.master.language_track_1.upcase,
               video_master_playlist_item.master.language_track_2.upcase,
               video_master_playlist_item.master.video_subtitles_1.upcase,
               '',
               '',
               'PENDING'.upcase,
               master_status.upcase,
               'PENDING'.upcase,
               subtitle_creation_status.upcase,
               'SIN'.upcase,
               '',
               video_master_playlist_item.master.synopsis.upcase]

      if video_master_playlist_item.master.present?
        sheet2.row(index + 1).replace entry

        format = Spreadsheet::Format.new color: :blue, pattern_fg_color: :white, pattern: 1, weight: :normal, size: 10,
                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
        sheet2.row(index + 1).default_format = format

        sheet2.row(index + 1).height = 36

        format = Spreadsheet::Format.new color: :blue, pattern_fg_color: :white, pattern: 1, weight: :normal, size: 10,
                                         align: :left, vertical_align: :middle, border: :thin, border_color: :black,
                                         :text_wrap => true
        sheet2.row(index + 1).set_format(4, format)
        sheet2.row(index + 1).set_format(5, format)
        sheet2.row(index + 1).set_format(20, format)

        format = Spreadsheet::Format.new color: :white, pattern_fg_color: :grey, pattern: 1, weight: :normal, size: 10,
                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
        sheet2.row(index + 1).set_format(12, format)
        sheet2.row(index + 1).set_format(13, format)

        format = Spreadsheet::Format.new color: :white, pattern_fg_color: :red, pattern: 1, weight: :normal, size: 10,
                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
        sheet2.row(index + 1).set_format(14, format)
        sheet2.row(index + 1).set_format(16, format)

        if video_master_playlist_item.master.location.nil?
          sheet2.row(index + 1).set_format(15, format)
        else
          format = Spreadsheet::Format.new color: :white, pattern_fg_color: :blue, pattern: 1, weight: :normal, size: 10,
                                           align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
          sheet2.row(index + 1).set_format(15, format)
        end

        if video_master_playlist_item.master.video_subtitles_1 == ''
          format = Spreadsheet::Format.new color: :white, pattern_fg_color: :blue, pattern: 1, weight: :normal, size: 10,
                                           align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
          sheet2.row(index + 1).set_format(17, format)
        else
          format = Spreadsheet::Format.new color: :blue, pattern_fg_color: :white, pattern: 1, weight: :normal, size: 10,
                                           align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
          sheet2.row(index + 1).set_format(17, format)
        end

        format = Spreadsheet::Format.new color: :white, pattern_fg_color: :green, pattern: 1, weight: :normal, size: 10,
                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
        sheet2.row(index + 1).set_format(18, format)

      end
    end

    sheet2.column(0).width = 7.5
    sheet2.column(1).width = 7.5
    sheet2.column(2).width = 7.5
    sheet2.column(3).width = 7.5
    sheet2.column(4).width = 25
    sheet2.column(5).width = 25
    sheet2.column(6).width = 10
    sheet2.column(7).width = 20
    sheet2.column(8).width = 10
    sheet2.column(9).width = 10
    sheet2.column(10).width = 10
    sheet2.column(11).width = 10
    sheet2.column(12).width = 10
    sheet2.column(13).width = 10
    sheet2.column(14).width = 12
    sheet2.column(15).width = 12
    sheet2.column(16).width = 12
    sheet2.column(17).width = 12
    sheet2.column(18).width = 12
    sheet2.column(19).width = 12
    sheet2.column(20).width = 50

    if @video_master_playlist.master_playlist_type.nil?
      video_type = ' '
    else
      video_type = ' ' + @video_master_playlist.master_playlist_type.name
    end

    data = StringIO.new ''
    book.write data
    send_data data.string,
              type: 'application/excel',
              disposition: 'attachment',
              filename: "#{airline_code}#{@video_master_playlist.start_cycle.strftime('%m%y')}#{video_type} Master.xls"
  end

  #def export_to_excel
  #  @video_master_playlist = VideoMasterPlaylist.find(params[:id])
  #
  #  #create excel file
  #
  #  book = Spreadsheet::Workbook.new
  #  sheet1 = book.create_worksheet name: 'Video Master Playlist'
  #
  #  # Header row
  #  format = Spreadsheet::Format.new color: :white, pattern_fg_color: :blue, pattern: 1, weight: :bold, size: 10,
  #                                   align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #  sheet1.row(0).default_format = format
  #  sheet1.row(0).height = 36
  #  headers = ['A/L',
  #             'CYCLE START',
  #             'CYCLE END',
  #             'PO#',
  #             'TITLE',
  #             'EPISODE',
  #             'EPS #',
  #             'DIST',
  #             'R/T MINS',
  #             'AUDIO 1',
  #             'AUDIO 2',
  #             'SUBS',
  #             'LICENSE FEE',
  #             'MATERIAL COST',
  #             'PO STATUS',
  #             'MASTER STATUS',
  #             'FILE STATUS',
  #             'SUBTITLE CREATION STATUS',
  #             'NEW',
  #             'HOLDOVER',
  #             'SYNOPSIS']
  #  sheet1.row(0).replace headers
  #
  #  if @video_master_playlist.airline_id.nil?
  #    airline_code = ''
  #  else
  #    airline_code = @video_master_playlist.airline.code
  #  end
  #
  #  # data rows
  #  video_master_playlist_items = @video_master_playlist.video_master_playlist_items_sorted
  #  video_master_playlist_items.each.with_index do |video_master_playlist_item, index|
  #
  #    if video_master_playlist_item.master.video.video_distributor.nil?
  #      distributor = ''
  #    else
  #      distributor = video_master_playlist_item.master.video.video_distributor.company_name
  #    end
  #
  #    if video_master_playlist_item.master.location.nil?
  #      master_status = 'Pending'
  #    else
  #      master_status = 'In'
  #    end
  #
  #    if video_master_playlist_item.master.video_subtitles_1 == ''
  #      subtitle_creation_status = 'NA'
  #    else
  #      subtitle_creation_status = "ENCODE WITH #{video_master_playlist_item.master.video_subtitles_1} SUBS"
  #    end
  #
  #    entry = [airline_code,
  #             @video_master_playlist.start_cycle.strftime("%m%y"),
  #             @video_master_playlist.end_cycle.strftime("%m%y"),
  #             '',
  #             video_master_playlist_item.master.video.programme_title.upcase,
  #             video_master_playlist_item.master.episode_title.upcase,
  #             video_master_playlist_item.master.episode_number.upcase,
  #             distributor.upcase,
  #             video_master_playlist_item.master.duration.upcase,
  #             video_master_playlist_item.master.language_track_1.upcase,
  #             video_master_playlist_item.master.language_track_2.upcase,
  #             video_master_playlist_item.master.video_subtitles_1.upcase,
  #             '',
  #             '',
  #             'PENDING'.upcase,
  #             master_status.upcase,
  #             'PENDING'.upcase,
  #             subtitle_creation_status.upcase,
  #             'SIN'.upcase,
  #             '',
  #             video_master_playlist_item.master.synopsis.upcase]
  #
  #    if video_master_playlist_item.master.present?
  #      sheet1.row(index + 1).replace entry
  #
  #      format = Spreadsheet::Format.new color: :blue, pattern_fg_color: :white, pattern: 1, weight: :normal, size: 10,
  #                                       align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #      sheet1.row(index + 1).default_format = format
  #
  #      sheet1.row(index + 1).height = 36
  #
  #      format = Spreadsheet::Format.new color: :blue, pattern_fg_color: :white, pattern: 1, weight: :normal, size: 10,
  #                                       align: :left, vertical_align: :middle, border: :thin, border_color: :black,
  #                                       :text_wrap => true
  #      sheet1.row(index + 1).set_format(4, format)
  #      sheet1.row(index + 1).set_format(5, format)
  #      sheet1.row(index + 1).set_format(20, format)
  #
  #      format = Spreadsheet::Format.new color: :white, pattern_fg_color: :grey, pattern: 1, weight: :normal, size: 10,
  #                                       align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #      sheet1.row(index + 1).set_format(12, format)
  #      sheet1.row(index + 1).set_format(13, format)
  #
  #      format = Spreadsheet::Format.new color: :white, pattern_fg_color: :red, pattern: 1, weight: :normal, size: 10,
  #                                       align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #      sheet1.row(index + 1).set_format(14, format)
  #      sheet1.row(index + 1).set_format(16, format)
  #
  #      if video_master_playlist_item.master.location.nil?
  #        sheet1.row(index + 1).set_format(15, format)
  #      else
  #        format = Spreadsheet::Format.new color: :white, pattern_fg_color: :blue, pattern: 1, weight: :normal, size: 10,
  #                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #        sheet1.row(index + 1).set_format(15, format)
  #      end
  #
  #      if video_master_playlist_item.master.video_subtitles_1 == ''
  #        format = Spreadsheet::Format.new color: :white, pattern_fg_color: :blue, pattern: 1, weight: :normal, size: 10,
  #                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #        sheet1.row(index + 1).set_format(17, format)
  #      else
  #        format = Spreadsheet::Format.new color: :blue, pattern_fg_color: :white, pattern: 1, weight: :normal, size: 10,
  #                                         align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #        sheet1.row(index + 1).set_format(17, format)
  #      end
  #
  #      format = Spreadsheet::Format.new color: :white, pattern_fg_color: :green, pattern: 1, weight: :normal, size: 10,
  #                                       align: :center, vertical_align: :middle, border: :thin, border_color: :black, :text_wrap => true
  #      sheet1.row(index + 1).set_format(18, format)
  #
  #    end
  #  end
  #
  #  sheet1.column(0).width = 7.5
  #  sheet1.column(1).width = 7.5
  #  sheet1.column(2).width = 7.5
  #  sheet1.column(3).width = 7.5
  #  sheet1.column(4).width = 25
  #  sheet1.column(5).width = 25
  #  sheet1.column(6).width = 10
  #  sheet1.column(7).width = 20
  #  sheet1.column(8).width = 10
  #  sheet1.column(9).width = 10
  #  sheet1.column(10).width = 10
  #  sheet1.column(11).width = 10
  #  sheet1.column(12).width = 10
  #  sheet1.column(13).width = 10
  #  sheet1.column(14).width = 12
  #  sheet1.column(15).width = 12
  #  sheet1.column(16).width = 12
  #  sheet1.column(17).width = 12
  #  sheet1.column(18).width = 12
  #  sheet1.column(19).width = 12
  #  sheet1.column(20).width = 50
  #
  #  if @video_master_playlist.master_playlist_type.nil?
  #    video_type = ' '
  #  else
  #    video_type = ' ' + @video_master_playlist.master_playlist_type.name
  #  end
  #
  #  data = StringIO.new ''
  #  book.write data
  #  send_data data.string,
  #            type: "application/excel",
  #            disposition: 'attachment',
  #            filename: "#{airline_code}#{@video_master_playlist.start_cycle.strftime("%m%y")}#{video_type} Master.xls"
  #end

  def sort
    params[:videoplaylist].each_with_index do |id,
        pos|
      VideoMasterPlaylistItem.find(id).update_attribute(:position,
                                                        pos+1)
    end
    render nothing: true
  end


  def duplicate

    @playlist = VideoMasterPlaylist.find(params[:id])
    @playlist_duplicate = VideoMasterPlaylist.create(
        start_cycle: @playlist.start_cycle,
        end_cycle: @playlist.end_cycle,
        user_id: current_user.id,
        media_instruction: @playlist.media_instruction
    )

    @video_master_playlist_items = VideoMasterPlaylistItem.where("video_master_playlist_id=#{@playlist.id}")
    .order("position ASC")

    @video_master_playlist_items.each do |item|

      VideoMasterPlaylistItem.create(
          master_id: item.master_id,
          position: item.position,
          mastering: item.mastering,
          video_master_playlist_id: @playlist_duplicate.id
      )

    end

    respond_to do |format|
      format.html { redirect_to(edit_video_master_playlist_path(@playlist_duplicate)) }
    end
  end

  def table_column_select
    puts session[:video_master_playlist_checked] = params[:checked]
    render nothing: true
  end

  private

  def get_columns
    @columns = ['#', 'Programme Title', 'Episode Title', 'Episode Number', 'Tape #', 'Lang Track 1', 'Lang Track 2', 'Lang Track 3', 'Lang Track 4', 'Lang Subs 1', 'Lang Subs 2', 'Tape Media', 'Tape Format', 'Tape Size', 'Time In', 'Time Out', 'Duration', 'Mastering', 'Aspect Ratio']
  end

end