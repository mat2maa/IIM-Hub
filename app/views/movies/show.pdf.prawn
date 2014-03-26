require 'open-uri'

prawn_document page_size: 'A4' do |pdf|

  pdf.font_families.update(
      'helvetica' => {
          light: Rails.root.join('.fonts', 'HelveticaLight.ttf').to_s,
          normal: Rails.root.join('.fonts', 'Helvetica.ttf').to_s,
          bold: Rails.root.join('.fonts', 'HelveticaBold.ttf').to_s
      },
      'SourceSans' => {
          light: Rails.root.join('.fonts', 'SourceSans-Light.ttf').to_s,
          normal: Rails.root.join('.fonts', 'SourceSans-Regular.ttf').to_s,
          semibold: Rails.root.join('.fonts', 'SourceSans-Semibold.ttf').to_s
      },
      'WenQuanYiMicroHei' => {
          normal: Rails.root.join('.fonts', 'wqy-microhei_0.ttf').to_s,
          light: Rails.root.join('.fonts', 'wqy-microhei_0.ttf').to_s
      },
      'BaekmukDotum' => {
          normal: Rails.root.join('.fonts', 'dotum.ttf').to_s,
          light: Rails.root.join('.fonts', 'dotum.ttf').to_s
      },
      'Thaitillium' => {
          normal: Rails.root.join('.fonts', 'Thaitillium.ttf').to_s,
          light: Rails.root.join('.fonts', 'Thaitillium.ttf').to_s
      },
      'ARIALUNI' => {
          normal: Rails.root.join('.fonts', 'arial.ttf').to_s,
          light: Rails.root.join('.fonts', 'arial.ttf').to_s
      }
  )

  pdf.font('helvetica')

  table_data = []

  table_data << ['Movie Title', @movie.movie_title.present? ? @movie.movie_title : '']
  table_data << ['Chinese Movie Title', @movie.chinese_movie_title.present? ? @movie.chinese_movie_title : '']
  table_data << ['Movie Type', @movie.movie_type_id.present? ? @movie.movie_type_id : '']
  table_data << ['Foreign Language Title', @movie.foreign_language_title.present? ? @movie.foreign_language_title : '']
  table_data << ['Theatrical Release Year', @movie.theatrical_release_year.present? ? @movie.theatrical_release_year : '']
  table_data << ['Airline Release Date', @movie.airline_release_date.present? ? @movie.airline_release_date : '']
  table_data << ['Personal Video Date', @movie.personal_video_date.present? ? @movie.personal_video_date : '']
  table_data << ['Screener Recieved Date', @movie.screener_received_date.present? ? @movie.screener_received_date : '']
  table_data << ['Screener Destroyed Date', @movie.screener_destroyed_date.present? ? @movie.screener_destroyed_date : '']
  table_data << ['Movie Distributor', @movie.movie_distributor.present? ? @movie.movie_distributor.company_name : '']
  table_data << ['Production Studio', @movie.production_studio.present? ? @movie.production_studio.company_name : '']
  table_data << ['Laboratory', @movie.laboratory.present? ? @movie.laboratory.company_name : '']
  table_data << ['Has Press Kit?', @movie.has_press_kit.present? ? @movie.has_press_kit : '']
  table_data << ['Gapp Number', @movie.gapp_number.present? ? @movie.gapp_number : '']
  table_data << ['Rating', @movie.rating.present? ? @movie.rating : '']
  table_data << ['Theatrical Runtime', @movie.theatrical_runtime.present? ? @movie.theatrical_runtime : '']
  table_data << ['Edited Runtime', @movie.edited_runtime.present? ? @movie.edited_runtime : '']
  table_data << ['Airline Rights', @movie.airline_rights.present? ? @movie.airline_rights : '']
  table_data << ['Release Versions', @movie.release_versions.present? ? @movie.release_versions : '']
  table_data << ['Language Tracks', @movie.language_tracks.present? ? @movie.language_tracks.join(', ') : '']
  table_data << ['Language Subtitles', @movie.language_subtitles.present? ? @movie.language_subtitles.join(', ') : '']
  table_data << ['Screener Remarks', @movie.screener_remarks.present? ? @movie.screener_remarks : '']
  table_data << ['Screener Remarks Other', @movie.screener_remarks_other.present? ? @movie.screener_remarks_other : '']
  table_data << ['Airline Countries', @movie.airline_countries.present? ? @movie.airline_countries : '']
  table_data << ['Movie Genres', @movie.movie_genres.present? ? @movie.movie_genres.map { |g| g.name }.join(', ') : '']
  table_data << ['Cast', @movie.cast.present? ? @movie.cast : '']
  table_data << ['Chinese Cast', @movie.chinese_cast.present? ? @movie.chinese_cast : '']
  table_data << ['Director', @movie.director.present? ? @movie.director : '']
  table_data << ['Chinese Director', @movie.chinese_director.present? ? @movie.chinese_director : '']
  table_data << ['Synopsis', @movie.synopsis.present? ? @movie.synopsis : '']
  table_data << ['Chinese Synopsis', @movie.chinese_synopsis.present? ? @movie.chinese_synopsis : '']
  table_data << ['IMDB Synopsis', @movie.imdb_synopsis.present? ? @movie.imdb_synopsis : '']
  table_data << ['Critics Review', @movie.critics_review.present? ? @movie.critics_review : '']
  table_data << ['Remarks', @movie.remarks.present? ? @movie.remarks : '']

  pdf.table table_data, :width => 500

end
