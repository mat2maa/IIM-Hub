require "open-uri"

logo = "#{Rails.root}/app/assets/images/iim-logo-transparent-hires.png"
bg_image = "#{Rails.root}/app/assets/images/pdf_bg.png"
bg_image_hires = "#{Rails.root}/app/assets/images/pdf_bg_hires.jpg"
bg_image_pdf = "#{Rails.root}/app/assets/images/pdf_bg.pdf"

prawn_document top_margin: 100, left_margin: 42, bottom_margin: 0, page_size: 'A4', background: bg_image do |pdf|

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
      },
      "WenQuanYiMicroHei" => {
          normal: Rails.root.join(".fonts", "wqy-microhei_0.ttf").to_s,
          light: Rails.root.join(".fonts", "wqy-microhei_0.ttf").to_s
      },
      "BaekmukDotum" => {
          normal: Rails.root.join(".fonts", "dotum.ttf").to_s,
          light: Rails.root.join(".fonts", "dotum.ttf").to_s
      }
  )

  pdf.font("helvetica")

  pdf.fill_color '000000'
  pdf.fill { pdf.rectangle [-100, 762], 695, 15 }

  pdf.formatted_text_box(
      [
          {
              text: "#{@video_playlist.airline.name if !@video_playlist.airline.nil? && !@video_playlist.airline_id.nil?} #{@video_playlist.start_cycle.strftime("%m%y")}",
              size: 12,
              color: 'FFFFFF',
              styles: [:bold]
          },
          {
              text: " / #{@video_playlist.video_playlist_type.name}s",
              size: 12,
              color: 'FFFFFF',
              styles: [:light]
          }
      ],
      at: [0, 760]
  )

  pdf.move_down(40)

#  pdf.image open(@video_playlist.videos.poster.path(:small))
#  pdf.image open("http://prawn.majesticseacreature.com/images/prawn_logo.png")
#  open("#{@video_playlist.videos.poster.path(:small)}")

  length = @video_playlist.videos.length
  @video_playlist.videos.each.with_index do |video, index|
    title = pdf.make_cell(content: video.programme_title) if video.programme_title.present?
    foreign_language_title = pdf.make_cell(content: video.foreign_language_title) if video.foreign_language_title.present?

    video_distributor = pdf.make_cell(content: video.video_distributor.company_name) if video.video_distributor.present?
    genres = pdf.make_cell(content: video.video_genres_string_with_parent) if video.video_genres_string_with_parent.present?
    commercial_run_time = pdf.make_cell(content: video.commercial_run_time.minutes.to_s) if video.commercial_run_time.present?
    language_tracks = pdf.make_cell(content: video.language_tracks.join(', ').to_s) if video.language_tracks.present?
    language_subtitles = pdf.make_cell(content: video.language_subtitles.join(', ').to_s) if video.language_subtitles.present?

    synopsis = pdf.make_cell(content: video.synopsis) if video.synopsis.present?

    image_path = "http://s3.amazonaws.com/iim#{video.poster.path(:small)}" if video.poster.present?

    pdf.bounding_box([0, pdf.cursor], width: 480, height: 120) do

      pdf.image open(image_path),
                at: [0, pdf.cursor],
                fit: [100, 100]

      titles = []
      titles.push([title]) if video.programme_title.present?
      titles.push([foreign_language_title]) if video.foreign_language_title.present?

      pdf.table(
          titles,
          width: 360,
          column_widths: [360],
          position: 120,
          cell_style: {
              font: "helvetica",
              font_style: :light,
              text_color: 'FFFFFF'
          }
      ) do
        cells.borders = []
        row(0).size = 21
        row(0).padding = [0, 2, 0, 2]
        row(1).size = 14
        row(1).padding = [0, 2, 4, 2]
      end

      information = []
      information.push(["Distributor", video_distributor]) if video.video_distributor.present?
      information.push(["Genres", genres]) if video.video_genres_string_with_parent.present?
      information.push(["Commercial Runtime", commercial_run_time]) if video.commercial_run_time.present?
      information.push(["Language Tracks", language_tracks]) if video.language_tracks.present?
      information.push(["Language Subtitles", language_subtitles]) if video.language_subtitles.present?

      pdf.table(
          information,
          width: 360,
          column_widths: [120, 240],
          position: 120,
          cell_style: {
              font: "SourceSans",
              font_style: :light,
              size:10,
              text_color: 'FFFFFF'
          }
      ) do
        cells.borders = []
        cells.padding = 2
      end
    end

    synopses = []
    synopses.push(["Synopsis:"])
    video.synopsis.present? ? synopses.push([synopsis]) : synopses.push(["N/A"])

    pdf.table(
        synopses,
        width: 480,
        column_widths: [480],
        position: 0,
        cell_style: {
            font: "SourceSans",
            text_color: 'FFFFFF',
            size: 10
        }
    ) do
      cells.borders = []
      cells.padding = 2
      row(0).font_style = :semibold
      row(1).font_style = :light
    end

    pdf.move_down(70) if(index % 2 == 0)

    # create a new page every 2 tables
    pdf.start_new_page(top_margin: 140, left_margin: 42, bottom_margin: 0, page_size: 'A4') if(index > 0 && index < length-1 && index % 2 == 1)

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