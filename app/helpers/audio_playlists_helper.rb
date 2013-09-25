module AudioPlaylistsHelper

  def total_duration playlist
    t = 0

    playlist.tracks.each do |track|
      t += track.duration/1000
    end

    duration_from_sec t
  end

  def in_out
    in_out = ['Inbound', 'Outbound', 'Inbound/Outbound']
  end

  def airline_duration
    airline_duration = ['15', '30', '40', '43', '45', '60', '90', '120']
  end

  def split_options
    s = [
        ["15 min", "15"],
        ["30 min", "30"],
        ["40 min", "40"],
        ["43 min", "43"],
        ["45 min", "45"],
        ["60 min", "60"],
        ["90 min", "90"]
    ]
  end

  def split_alert split_duration, accum_duration

    split = Split.where(duration: split_duration)

    s = ''

    if !split_duration.nil? && split_duration!=0 && !split.empty?
      if (accum_duration < split[0].more_than || accum_duration > split[0].less_than)
        s = 'alert'
      end
    end

    return s

  end

  #   30 Mins Split   Total Accumulated Duration must be > 30 mins 30 secs and < 31 mins
  #   45 Mins Split   Total Accumulated Duration must be > 45 mins 45 secs and < 46 mins 30 secs mins
  #   60 Mins Split   Total Accumulated Duration must be > 61 mins and < 62 mins
  #   90 Mins Split   Total Accumulated Duration must be > 91 mins 30 secs and < 93 mins
  #   120 Mins Split   Total Accumulated Duration must be > 122 mins and < 124 mins


  def tot_dur_split_alert airline_duration, total_duration

    split = Split.where(duration: airline_duration)

    s = ''

    if !airline_duration.nil? && airline_duration!=0 && !split.empty?
      if (total_duration < split[0].more_than || total_duration > split[0].less_than)
        s = 'alert'
      end
    end

    return s

  end

  #   Airline Duration 30 Mins    Total Accumulated Duration must be > 30 mins 30 secs and < 31 mins
  #   Airline Duration 45 Mins    Total Accumulated Duration must be > 45 mins 45 secs and < 46 mins 30 secs mins
  #   Airline Duration 60 Mins    Total Accumulated Duration must be > 61 mins and < 62 mins
  #   Airline Duration 90 Mins    Total Accumulated Duration must be > 91 mins 30 secs and < 93 mins
  #   Airline Duration 120 Mins    Total Accumulated Duration must be > 122 mins and < 124 mins


  def is_nil_alert i
    s = ""
    if i.nil? || i==""
      s = "class='alert'"
    end
  end

  def url_exists?(url)
    uri = URI.parse(url)
    http_conn = Net::HTTP.new(uri.host, uri.port)
    resp, data = http_conn.head(uri.path, nil)
    resp.code == "200"
  end

end
