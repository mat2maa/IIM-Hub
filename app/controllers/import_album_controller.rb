class ImportAlbumController < ApplicationController
  
  before_filter :require_user, :only => [:find_release, :import_release]
  before_filter :http_authenticate, :only => [:find_albums, :cddb_import, :update_album_mp3_exists]
	filter_access_to :find_release
	filter_access_to :import_release
	protect_from_forgery :except => [:itunes_import]
	

  def index
    
  end
  
  def find_release
  
    @q = MusicBrainz::Webservice::Query.new 
	  #rfilter = MusicBrainz::Webservice::ReleaseFilter.new(
  	#		:artist => params[:artist], 
  	#		:title => params[:title])
  	rfilter = MusicBrainz::Webservice::ReleaseFilter.new(
			:query => params[:query], 
			:artist => params[:artist], 
			:title => params[:title],
			:limit => 100 )

    @results = @q.get_releases(rfilter)
    		
  end
  
  def import_release
    release_id = params[:id]
	
	  #get release info
	
  	q = MusicBrainz::Webservice::Query.new
    	release_id = release_id
    	release = q.get_release_by_id(release_id, :artist=>true, :tracks=>true)
	
  	#add release to database
	
  	album = Album.new
  	album.title_original = release.title
  	album.artist_original = release.artist.name	 
  	album.musicbrainz_id = release.id.uuid	  
  	album.to_delete = 0
  	album.label_id = ''
  	album.save(false)
	
  	#add tracks to database
	
  	release.tracks.each_with_index do |rtrack, i|
  	  track = Track.new
  	  track.to_delete = 0
  	  track.album_id = album.id
  	  track.title_original = rtrack.title
  	  track.artist_original = release.artist.name
  	  track.musicbrainz_id = rtrack.id.uuid
  		if rtrack.duration.nil?
  			duration =0
  		else
  			duration = rtrack.duration
  		end
  	  track.duration = duration
  	  track.track_num = i+1
  	  track.save(false)
	
  	end
	
    album.total_duration = album.duration
  	album.save(false)
	
  	#redirect to album info
	
  	redirect_to edit_album_path(album)
  end
  
  def update
  
  end
  
  def itunes_import   
    
    @album = params["album"]
    @tracks = params["tracks"]
    @user = User.find_by_login("applescript")
    
    if @user.valid_password?(params["pw"])
    
      if verify_iim_app(params["app_id"])
        #add release to database
      	album = Album.new
      	album.title_original = @album["album_title"]
      	album.artist_original = @album["album_artist"]
      	album.disc_count = @album["disc_count"]
      	album.disc_num = @album["disc_number"]
      	album.release_year = @album["year"]
      	album.compilation = @album["compilation"]
      	genre = Genre.find(:all,:conditions=>{:name=>@album["genre"]})
    	  album.genres << genre
    	  album.genre = @album["genre"]
      	album.to_delete = 0
      	album.label_id = ''
      	album.save(false)

      	#add tracks to database

      	@tracks.each_with_index do |rtrack, i|
      	  track = Track.new
      	  track.to_delete = 0
      	  track.album_id = album.id
      	  track.composer = rtrack["composer"]
      	  track.title_original = rtrack["title"]
      	  track.artist_original = rtrack["artist"]
      	  track.duration = rtrack["duration"]
      	  track.track_num = rtrack["track_number"]
      	  genre = Genre.find(:all,:conditions=>{:name=>rtrack["genre"]})
      	  track.genres << genre
      	  track.genre = rtrack["genre"]
      	  track.save(false)

      	end

        album.total_duration = album.duration
      	album.save(false)
        @result="success"
      else
        @result="Invalid Application ID"
      end
    else
      @result="Invalid Password"
    end
    respond_to do  |format|
      format.html {render :layout => false }
    end
       
  end
  
  # returns list of albums to applescript
  # curl -d "var=1" http://username:password@localhost:3000/import_album/find_albums.xml"
  def find_albums
      album_title = params["album_title"]
      album_artist = params["album_artist"] 
      release_year = params["release_year"]            
      @albums = Album.find(:all, :conditions=>{:title_original=>album_title, :artist_original=>album_artist, :release_year=>release_year})
      respond_to do |format|
        format.xml{render :xml=>@albums, :status=> :found}
      end  
  end
  
  # imports album details from itunes from applescript and return album id
  # curl -d "album[album_title]=test&album[album_artist]=artist&album[genre]=Rock&tracks[][title]&tracks[][duration]=10000=Track" http://login:password@localhost:3000/import_album/cddb_import
  def cddb_import
    @album = params["album"]
    @tracks = params["tracks"]
    
    #add release to database
  	album = Album.new
  	album.title_original = @album["album_title"]
  	album.artist_original = @album["album_artist"]
  	album.disc_count = @album["disc_count"]
  	album.disc_num = @album["disc_number"]
  	album.release_year = @album["year"]
  	album.compilation = @album["compilation"]
  	genre = Genre.find(:all,:conditions=>{:name=>@album["genre"]})
	  album.genres << genre
	  album.genre = @album["genre"]
  	album.to_delete = 0
  	album.label_id = ''
  	album.mp3_exists = true
  	album.save(false)

  	#add tracks to database

  	@tracks.each_with_index do |rtrack, i|
  	  track = Track.new
  	  track.to_delete = 0
  	  track.album_id = album.id
  	  track.composer = rtrack["composer"]
  	  track.title_original = rtrack["title"]
  	  track.artist_original = rtrack["artist"]
  	  track.duration = rtrack["duration"]
  	  track.track_num = rtrack["track_number"]
  	  genre = Genre.find(:all,:conditions=>{:name=>rtrack["genre"]})
  	  track.genres << genre
  	  track.genre = rtrack["genre"]
  	  track.mp3_exists = true
  	  track.save(false)

  	end

    album.total_duration = album.duration
  	album.save(false)
    
    respond_to do  |format|
      format.html {render :text=> album.id }
    end
  end
  
  # set mp3_exists flag to true for albums that exist already, and just had mp3s ripped
  # curl -d "id=123" http://login:password@localhost:3000/import_album/update_album_mp3_exists
  def update_album_mp3_exists 
    @album = Album.find(params[:id])
    @album.mp3_exists = true
    
    @album.tracks.each do |track|
      track.mp3_exists = true
      track.mp3_exists_will_change!
      track.save(false)
    end
    @album.mp3_exists_will_change!
    @album.save(false)
    
    respond_to do  |format|
      format.html {render :text=> "success"}
    end
  end
    
  protected 
  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @user = User.find_by_login(username)
      !@user.nil? && @user.valid_password?(password) && (@user.roles.member? :administrator or @user.roles.member? :programmer)
    end
  end
  
end
