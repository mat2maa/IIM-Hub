class TracksController < ApplicationController
  before_filter :require_user
	filter_access_to :all

  def index
    dur_min = (params[:dur_min_min].to_i * 60  *1000) + (params[:dur_min_sec].to_i * 1000)
	  dur_max = (params[:dur_max_min].to_i * 60  *1000) + (params[:dur_max_sec].to_i * 1000)
  	if !params['search'].nil? 
  	    @search = Track.ransack(params[:q])
        @tracks = @search.result(distinct: true)
                         .paginate(page: params[:page], per_page: 10)

  	else 
  		@search = Track.ransack(params[:q])
      @tracks = @search.result(distinct: true)
                       .order("id DESC")
                       .paginate(page: params[:page], per_page: 10)
  	end

    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
    @tracks_count = @tracks.count

    if !dur_max.zero?
  	    @search.conditions.duration_greater_than = dur_min
    	  @search.conditions.duration_less_than = dur_max
    end
  end
  
  def new
    @track = Track.new  
    @track.album_id=params[:id]
    @track.duration = 0
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def create
	
    track = params[:track]
    @track = Track.new(params[:track])
    @track.to_delete = 0   
    @track.duration = (params[:dur_min].to_i * 60  *1000) + (params[:dur_sec].to_i * 1000)
  	@track.track_num = Track.count(:conditions => {:album_id => track[:album_id]}) + 1
		
		@track.label = @track.album.label.name if !@track.album.label_id.nil? 
		  
     respond_to do |format|
      if @track.save
        @track.album.total_duration = @track.album.duration
        @track.album.save(false)
        flash[:notice] = 'Track was successfully created.'
        format.html { redirect_to edit_album_path(@track.album) }
      else
        format.html { render :action => "new" }
      end
    end
  end
    
  def show
    @track = Track.find(params[:id])
	  @genres = Genre.find(:all)    
	  @playlists = AudioPlaylistTrack.find(:all, :conditions=>['track_id=?', params[:id]])
	  respond_to do |format|
      format.html
      format.xml{ render :xml => @track } 
    end
  end
  
  def edit
    @track = Track.find(params[:id])
	  @genres = Genre.find(:all)   
  end
  
  def update
    @track = Track.find(params[:id])
	  @playlists = AudioPlaylistTrack.find(:all, :conditions=>['track_id=?', params[:id]])
    @playlists.each do |audio_playlist_track|
		   audio_playlist_track.audio_playlist.updated_at_will_change!
       audio_playlist_track.audio_playlist.save
     end
	  @track.duration = (params[:dur_min].to_i * 60  *1000) + (params[:dur_sec].to_i * 1000)
		@track.label = @track.album.label.name if !@track.album.label_id.nil?
		@track.save(false)
						
	  respond_to do |format|
			
				if @track.update_attributes(params[:track])
				  if !params[:track][:genre_ids].nil?
  				  genres = params[:track][:genre_ids]
            i=0
    				g=""
       			genres.each do |genre|

        				if i==0
         					g = Genre.find(genre).name
         				else
         					g = g + ", " + Genre.find(genre).name
         				end
    						i+=1
        		end
    				@track.genre = g
          end
          @track.attributes = params[:track]
  				@track.save(false)
				  flash[:notice] = 'Track was successfully updated.'
          format.html { redirect_to edit_track_path(@track) }
				else
            @genres = Genre.find(:all)   
        	format.html { render :action => "edit" }
				end
		
		end
  end
  
  def destroy
    @track = Track.find(params[:id])
    
    tot_albumplaylistitems =AlbumPlaylistItem.count(:conditions => 'album_id=' + @track.album_id.to_s )	
	  tot_audioplaylisttracks =AudioPlaylistTrack.count(:joins => 'left join tracks on tracks.id=audio_playlist_tracks.track_id', :conditions => 'track_id=' + params[:id] )
	  
	  if  tot_albumplaylistitems.zero? && tot_audioplaylisttracks.zero?
    
      if permitted_to? :admin_delete, :tracks
        @track.album.total_duration = @track.album.duration
        @track.album.save(false)
        @track.destroy
        @track_is_deleted = true
      else
        @track.to_delete = true
        @track.save(false)
        flash[:notice] = 'Track will be deleted when approved by administrator'
        @track_is_deleted = false
      end
    else
  	  flash[:notice] = 'Track could not be deleted, track is in use for by playlists'
  	  @track_is_deleted = false
  	end 

    respond_to do |format|
      format.html { redirect_to(:back) }
      format.js
    end
  end
  
  def show_genre
	  @genres = Genre.find(:all)    
  	@track = Track.find(params[:id])
  end  
  
  def show_lyrics_form
	  @track = Track.find(params[:id])
  end
  
  def show_playlists
	  @track = Track.find(params[:id])
	  @playlists = AudioPlaylistTrack.find(:all, :conditions=>['track_id=?', params[:id]], :group=>:audio_playlist_id) 
  end
  
  def restore
    @track = Track.find(params[:id])
    @track.to_delete = false
    @track.save(false)
    flash[:notice] = 'Track has been restored'
    respond_to do |format|
        format.html { redirect_to(:back) }
        format.js
    end
  end
  
end
