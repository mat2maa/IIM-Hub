#encoding: utf-8

class PopulateAlbumCategories < ActiveRecord::Migration
  def up
    @album_categories = [['ABK', 'Audio Books'],['AI', 'Asian Instrumentals'],['AR', 'Arabic Pop'],['ARC', 'Arabic Classical'],['ARI', 'Arabic Instrumental'],['ART', 'Artists Soundbites'],['BL', 'Blues'],['CCN', 'Chinese Comedy'],['CEL', 'Chinese Easy Listening'],['CFM', 'Chinese Folk Music (Mostly Instrumentals)'],['CFS', 'Chinese Folk Music (With Vocals)'],['CL', 'Classical'],['CMDY', 'English Comedy'],['CN', 'Chinese Pop'],['CNK', 'Chinese Kids Music'],['CNY', 'Chinese New Year Music'],['CO', 'Country'],['COP', 'Chinese Opera'],['CPL', 'Compilations'],['CTO', 'Canto Pop'],['DC', 'Dance'],['E', 'English Pop (for albums that are of R&B, Soul, Rock genre you may categorize them here)'],['EI', 'English Instrumental'],['EL', 'English Easy Listening/Old Classic English albums (e.g. The Beatles, ABBA, etc…)'],['ENK', 'English Kids Music'],['ENKA', 'Enka Music'],['FR', 'French Music'],['GER', 'German Music'],['GZL', 'Ghazal'],['HI', 'Hindi Music'],['HOK', 'Hokkien Music'],['IND', 'Indonesian Music'],['IT', 'Italian Music'],['JP', 'Japanese Pop'],['JPK', 'Japanese Kids Music'],['JZ', 'Jazz'],['KR', 'Korean Pop'],['KLJ', 'Khaleeji Pop'],['LIV', 'Live Music Compilations'],['LP', 'Latin Pop'],['ML', 'Malay Music'],['MLYM', 'Malayalam'],['NA', 'New Age'],['OP', 'Opera'],['PAK', 'Pakistani Music'],['PH', 'Filipino Music'],['POR', 'Portuguese Music'],['RFM', 'Royal Free Music'],['RUS', 'Russian Music'],['RLG', 'Religious'],['SG', 'Singaporean Music'],['SPA', 'Spanish Music'],['ST', 'Movie/Drama/Musical Soundtracks'],['SWE', 'Swedish Music'],['TA', 'Tamil Music'],['TH', 'Thai Music'],['THCPL', 'Thai Compilation'],['THJZ', 'Thai Jazz Music'],['TURK', 'Turkish Music'],['TWN', 'Taiwanese Music (Taiwanese Indie Bands that sings in English)'],['WO', 'World Music'],['XM', 'Christmas Music']]

    @album_categories.each do |c|
      AlbumCategory.create(code: c[0], name: c[1])
    end
  end

  def down
    AlbumCategory.all.each do |a|
      a.destroy
    end
  end
end
