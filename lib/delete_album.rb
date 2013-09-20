class DeleteAlbum < Struct.new(:options)

  def perform

    #Deleting album from QNAP NAS

    require 'rubygems'
    require 'zip/zip'
    require 'net/http'
    require 'net/ftp'
    require 'fileutils'

    # get album ID
    @album_id = options[:album_id]

    # Delete album via ftp
    ftp = Net::FTP::new("imagesinmotion.no-ip.biz")
    ftp.passive = true

    if ftp.last_response_code == "220" # Service read for new user

      ftp.login("admin", "iiMusix1")
      if ftp.last_response_code == "200" # Command OK
        ftp.chdir("/Qmultimedia")
        if ftp.last_response_code == "250" # Requested file action OK completed

          begin
            album_tracks = ftp.nlst(@album_id.to_s)
            album_tracks.each do |track|
              ftp.delete(track)
            end
          rescue => e
            p e.message
            p e.backtrace
          end

          if ftp.last_response_code == "250" # Requested file action OK completed

            ftp.rmdir(@album_id.to_s)

          end # Deleted album tracks

        end # Changed to Qmultimedia directory

      end # Successful login

    end # Successful connection

  end # perform

end