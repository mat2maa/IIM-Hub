require "open-uri"

logo = "#{Rails.root}/app/assets/images/iim-logo-transparent-hires-new.png"
bg_image = "#{Rails.root}/app/assets/images/pdf_bg.png"
bg_image_hires = "#{Rails.root}/app/assets/images/pdf_bg_hires.jpg"
bg_image_pdf = "#{Rails.root}/app/assets/images/pdf_bg.pdf"
missing_image = "#{Rails.root}/app/assets/images/posters/missing_small.png"

prawn_document top_margin: 100,
               left_margin: 42,
               bottom_margin: 0,
               page_size: 'A4',
               background: bg_image do |pdf|

  pdf.font_families.update(
      "helvetica" => {
          light: Rails.root.join(".fonts", "HelveticaLight.ttf").to_s,
          normal: Rails.root.join(".fonts", "Helvetica.ttf").to_s,
          bold: Rails.root.join(".fonts", "HelveticaBold.ttf").to_s
      },
      "SourceSans" => {
          light: Rails.root.join(".fonts", "SourceSans-Light.ttf").to_s,
          normal: Rails.root.join(".fonts", "SourceSans-Regular.ttf").to_s,
          semibold: Rails.root.join(".fonts", "SourceSans-Semibold.ttf").to_s
      },
      "WenQuanYiMicroHei" => {
          normal: Rails.root.join(".fonts", "wqy-microhei_0.ttf").to_s,
          light: Rails.root.join(".fonts", "wqy-microhei_0.ttf").to_s
      },
      "BaekmukDotum" => {
          normal: Rails.root.join(".fonts", "dotum.ttf").to_s,
          light: Rails.root.join(".fonts", "dotum.ttf").to_s
      },
      "Thaitillium" => {
          normal: Rails.root.join(".fonts", "Thaitillium.ttf").to_s,
          light: Rails.root.join(".fonts", "Thaitillium.ttf").to_s
      },
      "ARIALUNI" => {
          normal: Rails.root.join(".fonts", "arial.ttf").to_s,
          light: Rails.root.join(".fonts", "arial.ttf").to_s
      }
  )

  pdf.font("helvetica")

  pdf.fill_color '000000'
  pdf.fill { pdf.rectangle [-100, 762], 695, 15 }

  pdf.formatted_text_box(
      [
          {
              text: "#{@movie_playlist.airline.name if !@movie_playlist.airline.nil? && !@movie_playlist.airline_id.nil?} #{@movie_playlist.start_cycle.strftime("%m%y")}",
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
      at: [0, 760]
  )

  pdf.move_down(40)

#  pdf.image open(@movie_playlist.movies.poster.path(:small))
#  pdf.image open("http://prawn.majesticseacreature.com/images/prawn_logo.png")
#  open("#{@movie_playlist.movies.poster.path(:small)}")

  length = @movie_playlist.movies.length
  @movie_playlist.movies.each.with_index do |movie, index|
    title = pdf.make_cell(content: movie.movie_title.capitalize) if movie.movie_title.present?
    chinese_title = pdf.make_cell(content: movie.chinese_movie_title) if movie.chinese_movie_title.present?
    foreign_language_title = pdf.make_cell(content: movie.foreign_language_title.capitalize + " (" + movie.movie_type.name.capitalize + ")") if movie.foreign_language_title.present?

    director = pdf.make_cell(content: movie.director) if movie.director.present?
    chinese_director = pdf.make_cell(content: movie.chinese_director) if movie.chinese_director.present?
    cast = pdf.make_cell(content: movie.cast) if movie.cast.present?
    chinese_cast = pdf.make_cell(content: movie.chinese_cast) if movie.chinese_cast.present?
    production_studio = pdf.make_cell(content: movie.production_studio.company_name) if movie.production_studio.present?
    theatrical_runtime = pdf.make_cell(content: movie.theatrical_runtime.to_s) if movie.theatrical_runtime.present?
    rating = pdf.make_cell(content: movie.rating) if movie.rating.present?
    genres = pdf.make_cell(content: movie.movie_genres_string) if movie.movie_genres_string.present?

    synopsis = pdf.make_cell(content: movie.synopsis) if movie.synopsis.present?
    chinese_synopsis = pdf.make_cell(content: movie.chinese_synopsis) if movie.chinese_synopsis.present?
    imdb_synopsis = pdf.make_cell(content: movie.imdb_synopsis) if movie.imdb_synopsis.present?
    #critics_review = pdf.make_cell(content: movie.critics_review.html_safe) if movie.critics_review.present?

    image_path = "http://s3.amazonaws.com/iim#{movie.poster.path(:small)}" if movie.poster.present?

    pdf.bounding_box([0, pdf.cursor], width: 480, height: 160) do

      if image_path.present? then
        pdf.image open(image_path),
                  at: [0, pdf.cursor],
                  fit: [100, 100]
      else
        pdf.image open(missing_image),
                  at: [0, pdf.cursor],
                  fit: [100, 100]
      end

      titles = []
      movie.chinese_movie_title.present? ? titles.push([chinese_title]) : titles.push([title])
      titles.push([foreign_language_title]) if movie.foreign_language_title.present?

      pdf.table(
          titles,
          width: 360,
          column_widths: [360],
          position: 120,
          cell_style: {
              font: "helvetica",
              font_style: :normal,
              text_color: 'FFFFFF'
          }
      ) do
        cells.borders = []
        row(0).size = movie.movie_title.length > 50 && !movie.chinese_movie_title.present? ? 16 : 21
        row(0).padding = [0, 2, 4, 2]
        row(0).font = "ARIALUNI" if movie.chinese_movie_title.present?

        row(1).size = 14
        row(1).padding = [0, 2, 4, 2]
        if movie.foreign_language_title.present? then
          !!movie.foreign_language_title.match(/^[a-zA-Z0-9_\-+ ]*$/) ? row(1).font = "helvetica" : row(1).font = "ARIALUNI"
        end
      end

      information = []
      movie.chinese_director.present? ? information.push(["Director", chinese_director]) : information.push(["Director", director])
      movie.chinese_director.present? ? information.push(["Cast", chinese_cast]) : information.push(["Cast", cast])
      information.push(["Production Studio", production_studio]) if movie.production_studio.present?
      information.push(["Theatrical Runtime", theatrical_runtime]) if movie.theatrical_runtime.present?
      information.push(["Rating", rating]) if movie.rating.present?
      information.push(["Genres", genres]) if movie.rating.present?

      pdf.table(
          information,
          width: 360,
          column_widths: [120, 240],
          position: 120,
          cell_style: {
              font: "SourceSans",
              font_style: :normal,
              size: 10,
              text_color: 'FFFFFF'
          }
      ) do
        cells.borders = []
        cells.padding = 2
        row(0).font = "ARIALUNI" if movie.chinese_director.present?
        row(1).font = "ARIALUNI" if movie.chinese_cast.present?
      end
    end

    synopses = []
    synopses.push(["Synopsis:"])
    if movie.chinese_synopsis.present? then
      synopses.push([chinese_synopsis])
    else
      movie.synopsis.present? ? synopses.push([synopsis]) : synopses.push(["N/A"])
    end
    synopses.push(["IMDB Synopsis:"]) if movie.imdb_synopsis.present?
    synopses.push([imdb_synopsis]) if movie.imdb_synopsis.present?
    #synopses.push(["Critics Review:"]) if movie.critics_review.present?
    #synopses.push([critics_review]) if movie.critics_review.present?

    if movie.synopsis.present? || movie.chinese_synopsis.present? || movie.imdb_synopsis.present? then
      pdf.table(
          synopses,
          width: 480,
          column_widths: [480],
          position: 0,
          cell_style: {
              font: "SourceSans",
              text_color: 'FFFFFF',
              size: 10,
              leading: 2
          }
      ) do
        cells.borders = []
        cells.padding = 2
        row(0).font_style = :semibold
        row(1).font_style = :normal
        row(1).font = "ARIALUNI" if movie.chinese_synopsis.present?
        row(2).font_style = :semibold
        row(3).font_style = :normal
        #row(4).font_style = :semibold
        #row(5).font_style = :normal
      end
    end

    pdf.move_down(70) if (index % 2 == 0)

    # create a new page every 2 tables
    pdf.start_new_page(top_margin: 140, left_margin: 42, bottom_margin: 0, page_size: 'A4') if (index > 0 && index < length-1 && index % 2 == 1)

    pdf.image open(logo),
              at: [0, 830],
              scale: 0.24

    pdf.font("SourceSans")

    pdf.fill_color '000000'
    pdf.fill { pdf.rectangle [-100, 15], 695, 15 }

    time = Time.new

    pdf.formatted_text_box(
        [
            {
                text: "Copyright Images In Motion, #{ time.year }",
                size: 10,
                color: 'FFFFFF',
                styles: [:light]
            }
        ],
        at: [0, 13]
    )
  end
end