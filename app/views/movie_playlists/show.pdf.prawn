require "open-uri"

bg_image = "#{Rails.root}/app/assets/images/pdf_bg.png"
bg_image_hires = "#{Rails.root}/app/assets/images/pdf_bg_hires.jpg"
bg_image_pdf = "#{Rails.root}/app/assets/images/pdf_bg.pdf"

prawn_document top_margin: 100, page_size: 'A4', background: bg_image do |pdf|

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

  pdf.move_down(70)

#  pdf.image open(@movie_playlist.movies.poster.path(:small))
#  pdf.image open("http://prawn.majesticseacreature.com/images/prawn_logo.png")
#  open("#{@movie_playlist.movies.poster.path(:small)}")

  table = @movie_playlist.movies.map do |movie|
    title = pdf.make_cell(content: movie.movie_title) if movie.movie_title.present?
    foreign_language_title = pdf.make_cell(content: movie.foreign_language_title) if movie.foreign_language_title.present?
    director = pdf.make_cell(content: movie.director) if movie.director.present?
    cast = pdf.make_cell(content: movie.cast) if movie.cast.present?
    production_studio = pdf.make_cell(content: movie.production_studio.company_name) if movie.production_studio.present?
    theatrical_runtime = pdf.make_cell(content: movie.theatrical_runtime.to_s) if movie.theatrical_runtime.present?
    image_path = "http://s3.amazonaws.com/iim#{movie.poster.path}" if movie.poster
.present?
    image = pdf.image open(image_path)
    rating = pdf.make_cell(content: movie.rating) if movie.rating.present?

    pdf.table([ ["Title", title],
            ["Foreign Language Title", foreign_language_title],
            ["Director", director],
            ["Cast", cast],
            ["Production Studio", production_studio],
            ["Theatrical Runtime", theatrical_runtime],
            ["Image", image_path],
            ["Rating", rating] ])

    pdf.move_down(50)
  end
end