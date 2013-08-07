require "open-uri"

logo = "#{Rails.root}/app/assets/images/iim-logo-transparent-hires-new.png"
bg_image = "#{Rails.root}/app/assets/images/pdf_bg.png"
bg_image_hires = "#{Rails.root}/app/assets/images/pdf_bg_hires.jpg"
bg_image_pdf = "#{Rails.root}/app/assets/images/pdf_bg.pdf"

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
              text: "#{@screener_playlist.airline.name if !@screener_playlist.airline.nil? && !@screener_playlist.airline_id.nil?} #{@screener_playlist.start_cycle.strftime("%m%y")}",
              size: 12,
              color: 'FFFFFF',
              styles: [:bold]
          },
          {
              text: " / Screener Playlist",
              size: 12,
              color: 'FFFFFF',
              styles: [:light]
          }
      ],
      at: [0, 760]
  )

  pdf.move_down(40)

#  pdf.image open(@screener_playlist.screeners.poster.path(:small))
#  pdf.image open("http://prawn.majesticseacreature.com/images/prawn_logo.png")
#  open("#{@screener_playlist.screeners.poster.path(:small)}")

  length = @screener_playlist.screeners.length
  @screener_playlist.screeners.each.with_index do |screener, index|
    title = pdf.make_cell(content: screener.video.programme_title) if screener.video.programme_title.present?
    episode_title = pdf.make_cell(content: screener.episode_title) if screener.episode_title.present?

    screener_distributor = pdf.make_cell(content: screener.video.video_distributor.company_name) if screener.video.video_distributor.present?
    genres = pdf.make_cell(content: screener.video.video_genres_string_with_parent) if screener.video.video_genres_string_with_parent.present?
    commercial_run_time = pdf.make_cell(content: screener.video.commercial_run_time.minutes.to_s) if screener.video.commercial_run_time.present?
    language_tracks = pdf.make_cell(content: screener.video.language_tracks.join(', ').to_s) if screener.video.language_tracks.present?
    language_subtitles = pdf.make_cell(content: screener.video.language_subtitles.join(', ').to_s) if screener.video.language_subtitles.present?

    synopsis = pdf.make_cell(content: screener.video.synopsis) if screener.video.synopsis.present?

    titles = []
    titles.push([title]) if screener.video.programme_title.present?
    titles.push([episode_title]) if screener.episode_title.present? && screener.episode_title.upcase != screener.video.programme_title.upcase

    pdf.table(
        titles,
        width: 480,
        column_widths: [480],
        position: 0,
        cell_style: {
            font: "helvetica",
            font_style: :light,
            text_color: 'FFFFFF'
        }
    ) do
      cells.borders = []
      row(0).size = screener.episode_title.length > 50 ? 16 : 21
      row(0).padding = [0, 2, 0, 2]
      row(1).size = 14
      row(1).padding = [0, 2, 4, 2]
    end

    information = []
    information.push(["Distributor", screener_distributor]) if screener.video.video_distributor.present?
    information.push(["Genres", genres]) if screener.video.video_genres_string_with_parent.present?
    information.push(["Commercial Runtime", commercial_run_time]) if screener.video.commercial_run_time.present?
    information.push(["Language Tracks", language_tracks]) if screener.video.language_tracks.present?
    information.push(["Language Subtitles", language_subtitles]) if screener.video.language_subtitles.present?

    pdf.table(
        information,
        width: 480,
        column_widths: [180, 300],
        position: 0,
        cell_style: {
            font: "SourceSans",
            font_style: :light,
            size: 10,
            text_color: 'FFFFFF'
        }
    ) do
      cells.borders = []
      cells.padding = 2
    end

    pdf.move_down(10)

    synopses = []
    synopses.push(["Synopsis:"])
    screener.video.synopsis.present? ? synopses.push([synopsis]) : synopses.push(["N/A"])

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
      row(1).font_style = :light
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