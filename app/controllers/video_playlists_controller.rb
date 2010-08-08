require "spreadsheet"
require 'stringio'

class VideoPlaylistsController < ApplicationController
  layout "layouts/application" ,  :except => :export
  before_filter :require_user
  filter_access_to :all
  
  def index
    if !params['search'].nil?
      @search = VideoPlaylist.new_search(params[:search])
    else 
      @search = VideoPlaylist.new_search(:order_by => :id, :order_as => "DESC")
    end
    
    @video_playlists, @video_playlists_count = @search.all, @search.count
  end
  
  def new
    @video_playlist = VideoPlaylist.new	
  end
  
  def create

    @video_playlist = VideoPlaylist.new(params[:video_playlist])
    @video_playlist.user_id = current_user.id
    @video_playlist.locked = false;

    respond_to do |format|
      if @video_playlist.save
        flash[:notice] = 'Playlist was successfully created.'

        format.html { redirect_to(edit_video_playlist_path(@video_playlist)) }

      else
        format.html { render :action => "new" }

      end
    end
  end
  
  def edit 
    @video_playlist = VideoPlaylist.find(params[:id],:include=>[:video_playlist_items,:videos])
  end 

  def update
    @video_playlist = VideoPlaylist.find(params[:id])

    respond_to do |format|
      if @video_playlist.update_attributes(params[:video_playlist])
        flash[:notice] = 'Playlist was successfully updated.'
        format.html { redirect_to(:back) }

      else
        format.html { render :action => "edit" }

      end
    end
  end
  
  def show 
    @video_playlist = VideoPlaylist.find(params[:id],:include=>[:video_playlist_items,:videos])
  end
  
  #display overlay
  def add_video_to_playlist
    if !params[:video_playlists].nil?
      @search = Video.new_search(params[:video_playlists])      
      @search.conditions.to_delete_equals=0
      @search.conditions.or_foreign_language_title_keywords = params[:video_playlists][:conditions][:or_video_title_keywords]  
      if !params[:search].nil?
        search = params[:search]        
        @search.per_page = search[:per_page] if !search[:per_page].nil? 
        @search.page = search[:page] if !search[:page].nil?
      end
      
      # if params[:screener][:destroyed] == "1"
      #   @search.conditions.screener_destroyed_date_not_equal = nil
      # end
      # if params[:screener][:held] == "1"
      #   @search.conditions.screener_destroyed_date_equals = ""
      # end
      
      @videos, @videos_count = @search.all, @search.count

    else
      @videos = nil
      @videos_count = 0
      @search = Video.new_search
    end

    respond_to do |format|
      format.html 

      format.js {
        if params[:video_playlists].nil? && params[:search].nil?
          render :action => 'add_video_to_playlist.rhtml', :layout => false 
        else
          render :update do |page| 
            page.replace_html "videos", :partial => "videos"
          end
        end      
      }
    end
  end
  
  #add video to playlist
  def add_video

    @video_playlist = VideoPlaylist.find(params[:id])
    @video_playlist_item = VideoPlaylistItem.new(:video_playlist_id => params[:id], :video_id => params[:video_id], :position => @video_playlist.video_playlist_items.count + 1)

    #check if video has been added to a previous playlist before    
    @playlists_with_video = VideoPlaylistItem.find(:all, 
    :conditions=>"video_id=#{params[:video_id]}",
    :group=>"video_playlist_id")
    @notice=""

    @video_to_add = Video.find(params[:video_id])

    if !@playlists_with_video.empty? && params[:add].nil?
      @playlists_with_video.each do |playlist_item|
        @notice += "<br/><div id='exists'>Note! This video #{@video_to_add.id.to_s} exists in playlist <a href='/video_playlists/#{playlist_item.video_playlist_id.to_s}' target='_blank'>#{playlist_item.video_playlist_id.to_s}</a></div>" if !playlist_item.video_playlist.nil?
      end     

    else
      if @video_playlist_item.save
        flash[:notice] = 'Video was successfully added.'
      end
    end
  end  
  
  #add selected videos to playlist
  def add_multiple_videos
    
    @notice = ""
    @video_playlist = VideoPlaylist.find(params[:playlist_id])
    video_ids = params[:video_ids]
    
    video_ids.each do |video_id|
      @video_playlist_item = VideoPlaylistItem.new(:video_playlist_id => params[:playlist_id], :video_id => video_id, :position => @video_playlist.video_playlist_items.count + 1)
    
      #check if video has been added to a previous playlist before    
      @playlists_with_video = VideoPlaylistItem.find(:all, 
      :conditions=>"video_id=#{video_id}",
      :group=>"video_playlist_id")

      @video_to_add = Video.find(video_id)
      if !@playlists_with_video.empty? && params[:add].nil?
        @playlists_with_video.each do |playlist_item|
          if !playlist_item.video_playlist.nil?
            if !playlist_item.video_playlist.airline_id.nil?
              airline_code = Airline.find(playlist_item.video_playlist.airline_id).code
            else
              airline_code = ""
            end
            @notice += "<br/><div id='exists'>Note! This video #{@video_to_add.programme_title.to_s} exists in playlist 
                        <a href='/video_playlists/#{playlist_item.video_playlist_id.to_s}' target='_blank'>#{airline_code}#{playlist_item.video_playlist.start_cycle.strftime("%m%y")}</a></div>
                        #{@template.link_to_remote("Continue adding " + @video_to_add.programme_title.to_s + " to playlist", 
                        :url => {:controller => "video_playlists", 
                        :action => "add_video", 
                        :id => params[:playlist_id], 
                        :video_id => video_id,
                        :add => 1},
                        :loading => "Element.show('spinner')",
                        :complete => "Element.hide('spinner')")}" 
          end
        end     
      else
        if @video_playlist_item.save
          flash[:notice] = 'Videos were successfully added.'
        end
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
  
  def print

    @video_playlist = VideoPlaylist.find(params[:id]) 	

    respond_to do  |format|
      format.html {render :layout => false }
    end
  end
  
  
  def export_to_excel
    @video_playlist = VideoPlaylist.find(params[:id])

    #create excel file

    book = Spreadsheet::Workbook.new
    sheet = SheetWrapper.new(book.create_worksheet)
    sheet.add_row ["Airline Name", "Start Cycle", "End Cycle"]

    if @video_playlist.airline_id.nil?
      airline_code = ''
      airline_name = ''
    else
      airline_code = @video_playlist.airline.code
      airline_name = @video_playlist.airline.name
    end

    sheet.add_row [airline_code, airline_name, @video_playlist.start_cycle.strftime("%B"),  @video_playlist.start_cycle.strftime("%Y"), @video_playlist.end_cycle.strftime("%B"),  @video_playlist.end_cycle.strftime("%Y")]

    sheet.add_lines(1)
    
    video_playlist_items = @video_playlist.video_playlist_items_sorted
    
    # Video Playlist Summary
    # header row
    sheet.add_row ["Position", "Programme Title", "Distributor", "Genre", "Commercial Run Time", "Episodes Available", "Synopsis", "Poster"]

    # data rows
    video_playlist_items.each do |video_playlist_item|

      if video_playlist_item.video.video_distributor.nil?
        video_distributor = ""
      else
        video_distributor = video_playlist_item.video.video_distributor.company_name
      end
        
      sheet.add_row [video_playlist_item.position, 
        video_playlist_item.video.programme_title, 
        video_distributor, 
        video_playlist_item.video.video_genres_string, 
        video_playlist_item.video.commercial_run_time.minutes, 
        video_playlist_item.video.episodes_available, 
        video_playlist_item.video.synopsis, 
        "http://hub.iim.com.sg" + video_playlist_item.video.poster.url]
      end

      sheet.add_lines(1)

    data = StringIO.new ''
    book.write data
    send_data data.string, :type=>"application/excel", 
    :disposition=>'attachment', :filename => "#{airline_code}#{@video_playlist.start_cycle.strftime("%m%y")} Video Playlist.xls"
  end
  
  def sort
    params[:videoplaylist].each_with_index do |id, pos|
      VideoPlaylistItem.find(id).update_attribute(:position, pos+1)
    end
    render :nothing => true
  end
  
  
  def duplicate

    @playlist = VideoPlaylist.find(params[:id])
    @playlist_duplicate = VideoPlaylist.create(
      :airline_id => @playlist.airline_id,
      :start_cycle => @playlist.start_cycle,
      :end_cycle => @playlist.end_cycle,
      :user_id => current_user.id
    )

    @playlist.video_playlist_items.each do |item|

      VideoPlaylistItem.create(
      :video_id => item.video_id,
      :position => item.position,
      :mastering => item.mastering,
      :video_playlist_id => @playlist_duplicate.id
      )

    end

    respond_to do |format|
      format.html { redirect_to(video_playlists_path) }
    end
  end
end