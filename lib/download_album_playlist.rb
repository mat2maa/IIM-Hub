class DownloadAlbumPlaylist < Struct.new(:options)

  def perform

    #Downloading mp3s from QNAP NAS

    require 'rubygems'
    require 'zip/zip'
    require 'net/http'
    require 'net/ftp'
    require 'fileutils'

    #get playlist information

    @playlist_id = options[:album_playlist_id]
    playlist = AlbumPlaylist.find(@playlist_id)

    @albums_found = playlist.albums

    @albums = []
    @tracks = []
    @albums_found.each do |a|
      a.tracks.each do |t|
        if t.mp3_exists?
          @tracks << t.track_num
          @albums << a.id
        end
      end
    end

    @playlist_type = playlist.class.to_s

    get_mp3_info = [@playlist_type, @playlist_id, @albums, @tracks]

    # Download files to public/zip/[Playlist ID] directory
    ftp = Net::FTP::new("imagesinmotion.no-ip.biz")
    ftp.passive = true

    if ftp.last_response_code == "220" # Service read for new user

      ftp.login("admin", "iiMusix1")
      if ftp.last_response_code == "200" # Command OK
        ftp.chdir("/Qmultimedia")
        if ftp.last_response_code == "250" # Requested file action OK completed

          begin
            playlist_type = get_mp3_info[0]
            playlist_id = get_mp3_info[1]
            albums = get_mp3_info[2]

            files = @albums.zip(@tracks).map { |a, b| "#{a}/#{b}.mp3" }
            files_count = files.count

            files.each.with_index do |file, index|
              filesize = ftp.size(file)
              transferred = 0
              # Output file to "#{Rails.root}/public/zip/[@playlist_type]/[@playlist_id]/[@album_id]/[@track_number].mp3"
              FileUtils.mkdir_p "#{Rails.root}/public/zip/#{playlist_type}/#{playlist_id}/#{albums[index]}"
              ftp.get(file, "#{Rails.root}/public/zip/#{playlist_type}/#{playlist_id}/#{file}", 819200) { |data|
                transferred += data.size
                file_percent = ((transferred).to_f/filesize.to_f)*100
                playlist.update_attributes job_current_progress: file_percent.round,
                                           job_current_track: index,
                                           job_total_tracks: files_count
              }
            end

            # Zip files
            directory = "#{Rails.root}/public/zip/#{playlist_type}/#{playlist_id}/"
            zipfile_name = "#{Rails.root}/public/zip/#{playlist_type}/#{playlist_id}.zip"

            # Remove previous zip file
            FileUtils.rm_f(zipfile_name)
            Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
              Dir[File.join(directory, '**', '**')].each do |file|
                zipfile.add(file.sub(directory, ''), file)
              end
            end
            FileUtils.chmod 0755, zipfile_name

            # tempfile = open(zipfile_name)
            # uploader = AlbumPlaylistZipUploader.new
            # uploader.store!(tempfile)
            # p = AlbumPlaylist.find(playlist_id)
            # p.album_playlist_zip = File.open(zipfile_name)
            # p.save!
          rescue => e
            p e.message
            p e.backtrace
          end

        end # Changed to Qmultimedia directory

      end # Successful login

    end # Successful connection

    playlist.update_attribute :job_finished_at, Time.current

  end # perform

end