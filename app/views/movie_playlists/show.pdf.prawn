bg_image = "#{Rails.root}/app/assets/images/pdf_bg.png"
bg_image_hires = "#{Rails.root}/app/assets/images/pdf_bg_hires.jpg"
bg_image_pdf = "#{Rails.root}/app/assets/images/pdf_bg.pdf"

prawn_document top_margin: 100, page_size: 'A4' do |pdf|

  pdf.font_families.update(
      "helvetica" => {
          light:    Rails.root.join(".fonts", "HelveticaLight.ttf").to_s,
          normal: Rails.root.join(".fonts", "Helvetica.ttf").to_s,
          bold:     Rails.root.join(".fonts", "HelveticaBold.ttf").to_s
      },
      "SourceSans" => {
          light:    Rails.root.join(".fonts", "SourceSans-Light.ttf").to_s,
          normal: Rails.root.join(".fonts", "SourceSans-Regular.ttf").to_s,
          semibold:     Rails.root.join(".fonts", "SourceSans-Semibold.ttf").to_s
      }
  )

  pdf.font("helvetica")

  pdf.fill_color '000000'
  pdf.fill { pdf.rectangle [-100, 730], 695, 15 }

  pdf.formatted_text_box(
      [
          {
              text: "#{@movie_playlist.airline.code if !@movie_playlist.airline.nil? && !@movie_playlist.airline_id.nil?} #{@movie_playlist.start_cycle.strftime("%m%y")}",
              size: 12,
              color: 'FFFFFF',
              styles: [:bold]
          },
          {
              text: " / #{@movie_playlist.movie_playlist_type.name}s",
              size: 12,
              color: 'FFFFFF',
              styles: [:light]
          }
      ],
      at: [0, 728]
  )

  pdf.move_down(30)

  movies = @movie_playlist.movies.map do |movie|
    [
        movie.id,
        movie.movie_title,
        movie.theatrical_release_year,
        movie.synopsis,
    ]
  end

  pdf.table(movies, width: 400, column_widths: [100, 100, 100, 100])

end