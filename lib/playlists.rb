module Playlists
  def duration ms
    if !ms.nil?
  
    sec = ms/1000

    min = sec/60
  
    sec = sec%60

    if sec < 10 :  sec = "0#{sec}"
    end 
    if sec == 0 :  sec = "00"
    end
    if min == 0 :  min = "0"
    end

    t = "#{min}:#{sec}"
    else 
    t = "0:00"
  end
  t
  end


end