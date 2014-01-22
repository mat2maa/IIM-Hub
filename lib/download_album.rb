class DownloadAlbum < Struct.new(:options)

  def perform

    #Downloading mp3s from QNAP NAS

    require 'rubygems'
    require 'zip/zip'
    require 'net/http'
    require 'net/ftp'
    require 'fileutils'

    #get playlist information

    @album_id = options[:album_id]
    album = Album.find(@album_id)

    @tracks_found = album.tracks_sorted.delete_if { |track| track.mp3_exists==false }

    @albums = @tracks_found.map { |t| t.album_id }.flatten
    @tracks = @tracks_found.map { |t| t.track_num }.flatten

    @album_type = album.class.to_s

    get_mp3_info = [@album_type, @album_id, @albums, @tracks]

    # Download files to tmp/[Playlist ID] directory
    ftp = Net::FTP::new("imagesinmotion.no-ip.biz")
    ftp.passive = true

    if ftp.last_response_code == "220" # Service read for new user

      ftp.login("admin", "iiMusix1")
      if ftp.last_response_code == "200" # Command OK
        ftp.chdir("/Qmultimedia")
        if ftp.last_response_code == "250" # Requested file action OK completed

          begin
            album_type = get_mp3_info[0]
            album_id = get_mp3_info[1]
            albums = get_mp3_info[2]
            tracks = get_mp3_info[3]

            files = @albums.zip(@tracks).map { |a, b| "#{a}/#{b}.mp3" }
            files_count = files.count

            files.each.with_index do |file, index|
              filesize = ftp.size(file)
              transferred = 0
              # Output file to "#{Rails.root}/tmp/[@album_type]/[@album_id]/[@album_id]/[@track_number].mp3"
              FileUtils.mkdir_p "#{Rails.root}/tmp/#{album_type}/#{album_id}/#{albums[index]}"
              ftp.get(file, "#{Rails.root}/tmp/#{album_type}/#{album_id}/#{file}", 819200) { |data|
                transferred += data.size
                file_percent = ((transferred).to_f/filesize.to_f)*100
                playlist.update_attributes job_current_progress: file_percent.round,
                                           job_current_track: index,
                                           job_total_tracks: files_count
              }
            end

            # Zip files
            directory = "#{Rails.root}/tmp/#{album_type}/#{album_id}/"
            zipfile_name = "#{Rails.root}/tmp/#{album_type}/#{album_id}.zip"

            # Remove previous zip file
            FileUtils.rm_f(zipfile_name)
            Zip::ZipFile.open(zipfile_name, Zip::ZipFile::CREATE) do |zipfile|
              Dir[File.join(directory, '**', '**')].each do |file|
                zipfile.add(file.sub(directory, ''), file)
              end
            end

            tempfile = open(zipfile_name)
            uploader = AlbumZipUploader.new
            uploader.store!(tempfile)
            p = Album.find(album_id)
            p.album_zip = File.open(zipfile_name)
            p.save!
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