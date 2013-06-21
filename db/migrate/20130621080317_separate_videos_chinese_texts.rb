# encoding: utf-8

class SeparateVideosChineseTexts < ActiveRecord::Migration
  def up
    Video.all.each do |video|

      if has_chinese_text?(video, :programme_title)
        split_chinese_text(video, :programme_title)

        video.save(validate: false)
      end

      if has_chinese_text?(video, :synopsis)
        split_chinese_synopsis(video, :synopsis)

        video.save(validate: false)
      end

    end
  end

  def down
  end

  private

  def has_chinese_text?(object, attribute)
    contains_cjk?(object.send(attribute))
  end

  def split_chinese_text(object, attribute)
    text = object.send(attribute)

    chinese, english = split_it(text)

    object.send(:"#{attribute}=", english)
    object.send(:"chinese_#{attribute}=", chinese)
  end

  def split_it(string)
    words = string.split(/\s+/)
    chinese_words, english_words = words.partition { |word| contains_cjk?(word) }

    [chinese_words.join(" "), english_words.join(" ")]
  end

  # Using a different function for synopses as some don't have a space at the beginning of the Chinese part.
  def split_chinese_synopsis(object, attribute)
    text = object.send(attribute)

    english, chinese = text.split( /\b\p{Han}|\b\p{Katakana}|\b\p{Hiragana}|\b\p{Hangul}/, 2 )

    object.send(:"#{attribute}=", english)
    object.send(:"chinese_#{attribute}=", chinese)
  end

  def contains_cjk?(string)
    !!(string =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/)
  end
end