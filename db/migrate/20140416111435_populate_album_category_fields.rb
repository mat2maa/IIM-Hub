class PopulateAlbumCategoryFields < ActiveRecord::Migration
  def up
    Album.all.each do |album|
      if album.cd_code.present? && album.cd_code != ''
        category_string = album.cd_code.gsub(/\s+/, '').scan(/\d+|\D+/)[0]
        album_category_auto_increment = album.cd_code.scan(/\d+|\D+/)[1]

        album_category = AlbumCategory.where('code = ?', category_string)
        if album_category.length != 0
          album_category_id = album_category.first.id
          if album.update_attributes album_category_id: album_category_id, album_category_auto_increment: album_category_auto_increment
            p 'Success!'
          else
            p album.errors.full_messages
          end
        else
          p "Could not find category for album #{album.id} with CD Code #{album.cd_code}"
          album_category = AlbumCategory.create(code: category_string, name: 'Default')
          album_category_id = album_category.id
          if album.update_attributes album_category_id: album_category_id, album_category_auto_increment: album_category_auto_increment
            p 'Success!'
          else
            p album.errors.full_messages
          end
        end
      end
    end
  end

  def down
    Album.all.each do |album|
        album.update_attributes album_category_id: nil, album_category_auto_increment: nil
    end
  end
end
