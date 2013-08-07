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
              text: "#{@video_master_playlist.airline.name if !@video_master_playlist.airline.nil? && !@video_master_playlist.airline_id.nil?} #{@video_master_playlist.start_cycle.strftime("%m%y")}",
              size: 12,
              color: 'FFFFFF',
              styles: [:bold]
          },
          {
              text: " / Video Master Playlist",
              size: 12,
              color: 'FFFFFF',
              styles: [:light]
          }
      ],
      at: [0, 760]
  )

  pdf.move_down(40)

#  pdf.image open(@video_master_playlist.video_masters.poster.path(:small))
#  pdf.image open("http://prawn.majesticseacreature.com/images/prawn_logo.png")
#  open("#{@video_master_playlist.video_masters.poster.path(:small)}")

  length = @video_master_playlist.masters.length
  @video_master_playlist.masters.each.with_index do |video_master, index|
    title = pdf.make_cell(content: video_master.episode_title) if video_master.episode_title.present?

    tape_media = pdf.make_cell(content: video_master.tape_media) if video_master.tape_media.present?
    tape_format = pdf.make_cell(content: video_master.tape_format) if video_master.tape_format.present?
    tape_size = pdf.make_cell(content: video_master.tape_size) if video_master.tape_size.present?
    aspect_ratio = pdf.make_cell(content: video_master.aspect_ratio) if video_master.aspect_ratio.present?
    video_subtitles_1 = pdf.make_cell(content: video_master.video_subtitles_1) if video_master.video_subtitles_1.present?
    video_subtitles_2 = pdf.make_cell(content: video_master.video_subtitles_2) if video_master.video_subtitles_2.present?
    language_track_1 = pdf.make_cell(content: video_master.language_track_1) if video_master.language_track_1.present?
    language_track_2 = pdf.make_cell(content: video_master.language_track_2) if video_master.language_track_2.present?
    language_track_3 = pdf.make_cell(content: video_master.language_track_3) if video_master.language_track_3.present?
    language_track_4 = pdf.make_cell(content: video_master.language_track_4) if video_master.language_track_4.present?
    time_in = pdf.make_cell(content: video_master.time_in) if video_master.time_in.present?
    time_out = pdf.make_cell(content: video_master.time_out) if video_master.time_out.present?
    duration = pdf.make_cell(content: video_master.duration) if video_master.duration.present?
    location = pdf.make_cell(content: video_master.location.to_s) if video_master.location.present?

    synopsis = pdf.make_cell(content: video_master.synopsis) if video_master.synopsis.present?

    titles = []
    titles.push([title]) if video_master.episode_title.present?

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
      row(0).size = video_master.episode_title.length > 50 ? 16 : 21
      row(0).padding = [0, 2, 0, 2]
    end

    information = []
    information.push(["Tape Media", video_master.tape_media.present? ? tape_media : "", "Tape Format", video_master.tape_format.present? ? tape_format : ""])
    information.push(["Tape Size", video_master.tape_size.present? ? tape_size : "", "Aspect Ratio", video_master.aspect_ratio.present? ? aspect_ratio : ""])
    information.push(["Video Subtitles 1", video_master.video_subtitles_1.present? ? video_subtitles_1 : "", "Video Subtitles 2", video_master.video_subtitles_2.present? ? video_subtitles_2 : ""])
    information.push(["Language Track 1", video_master.language_track_1.present? ? language_track_1 : "", "Language Track 2", video_master.language_track_2.present? ? language_track_2 : ""])
    information.push(["Language Track 3", video_master.language_track_3.present? ? language_track_3 : "", "Language Track 4", video_master.language_track_4.present? ? language_track_4 : ""])
    information.push(["Time In", video_master.time_in.present? ? time_in : "", "Time Out", video_master.time_out.present? ? time_out : ""])
    information.push(["Duration", video_master.duration.present? ? duration : "", "Location", video_master.location.present? ? location : ""])

    pdf.table(
        information,
        width: 480,
        column_widths: [80, 160, 80, 160],
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

    pdf.move_down(5)

    synopses = []
    synopses.push(["Synopsis:"])
    video_master.synopsis.present? ? synopses.push([synopsis]) : synopses.push(["N/A"])

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

    pdf.move_down(30) if (index % 3 == 0 || index % 3 == 1)

    # create a new page every 2 tables
    pdf.start_new_page(top_margin: 140, left_margin: 42, bottom_margin: 0, page_size: 'A4') if (index > 0 && index < length-1 && index % 3 == 2)

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