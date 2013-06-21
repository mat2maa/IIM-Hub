# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130621080317) do

  create_table "airline_rights_countries", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "airline_rights_countries_movies", :id => false, :force => true do |t|
    t.integer  "airline_rights_country_id"
    t.integer  "movie_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "airlines", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "album_playlist_items", :force => true do |t|
    t.integer  "album_playlist_id"
    t.integer  "album_id"
    t.integer  "position"
    t.integer  "category_id",       :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "album_playlist_items", ["album_playlist_id"], :name => "index_album_playlist_items_on_album_playlist_id"

  create_table "album_playlists", :force => true do |t|
    t.string   "client_playlist_code"
    t.integer  "airline_id"
    t.string   "in_out"
    t.date     "start_playdate"
    t.date     "end_playdate"
    t.integer  "user_id"
    t.boolean  "locked"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "album_services", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "albums", :force => true do |t|
    t.integer  "label_id"
    t.string   "title_original"
    t.string   "title_english"
    t.string   "artwork"
    t.string   "cd_code"
    t.integer  "disc_num"
    t.integer  "disc_count"
    t.integer  "release_year"
    t.string   "artist_original"
    t.string   "artist_english"
    t.text     "synopsis"
    t.integer  "publisher_id"
    t.boolean  "live_album",         :default => false
    t.boolean  "explicit_lyrics",    :default => false
    t.boolean  "to_delete",          :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cover_file_name"
    t.string   "cover_content_type"
    t.integer  "cover_file_size"
    t.datetime "cover_updated_at"
    t.string   "genre",              :default => "",    :null => false
    t.text     "musicbrainz_id"
    t.integer  "language_id"
    t.string   "gender"
    t.integer  "origin_id"
    t.integer  "total_duration"
    t.integer  "tracks_count",       :default => 0
    t.boolean  "compilation",        :default => false
    t.boolean  "mp3_exists",         :default => false
  end

  create_table "albums_genres", :id => false, :force => true do |t|
    t.integer  "genre_id"
    t.integer  "album_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "audio_playlist_tracks", :force => true do |t|
    t.integer  "audio_playlist_id"
    t.integer  "track_id"
    t.integer  "position"
    t.text     "mastering"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "split"
    t.string   "vo_duration"
  end

  add_index "audio_playlist_tracks", ["audio_playlist_id"], :name => "index_audio_playlist_tracks_on_audio_playlist_id"

  create_table "audio_playlists", :force => true do |t|
    t.string   "client_playlist_code"
    t.integer  "airline_id"
    t.string   "in_out"
    t.date     "start_playdate"
    t.date     "end_playdate"
    t.integer  "vo_id"
    t.text     "mastering"
    t.integer  "user_id"
    t.integer  "program_id"
    t.boolean  "locked",               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "program_cache",                           :null => false
    t.string   "airline_cache",                           :null => false
    t.string   "airline_duration"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "commercial_run_times", :force => true do |t|
    t.integer  "minutes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "commercial_run_times_videos", :id => false, :force => true do |t|
    t.integer  "commercial_run_time_id"
    t.integer  "video_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "covers", :force => true do |t|
    t.integer  "album_id"
    t.integer  "parent_id"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.string   "content_type"
    t.string   "filename"
    t.string   "thumbnail"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "covers", ["album_id", "parent_id"], :name => "index_covers_on_album_id_and_parent_id"

  create_table "filemaker_album_playlists", :id => false, :force => true do |t|
    t.integer "id"
    t.integer "airline_id"
    t.string  "program"
    t.string  "in_out"
    t.string  "play_date_start_month"
    t.integer "play_date_start_year"
    t.string  "play_date_end_month"
    t.integer "play_date_end_year"
    t.integer "user_id"
  end

  create_table "filemaker_albums", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "title_original"
    t.string  "title_english"
    t.string  "artist_original"
    t.string  "artist_english"
    t.string  "cd_code"
    t.string  "disc_num"
    t.string  "disc_count"
    t.string  "release_year"
    t.string  "label"
    t.string  "publisher"
    t.text    "genre"
    t.text    "synopsis"
    t.string  "live_album"
    t.string  "explicit_lyrics"
  end

  create_table "filemaker_track_playlists", :id => false, :force => true do |t|
    t.integer "id"
    t.integer "airline_id"
    t.string  "client_playlist_code"
    t.string  "program"
    t.string  "in_out"
    t.string  "play_date_start_month"
    t.integer "play_date_start_year"
    t.string  "play_date_end_month"
    t.integer "play_date_end_year"
    t.string  "playlist_duration"
    t.integer "total_minutes"
    t.integer "total_seconds"
    t.text    "mastering"
    t.string  "programmer"
    t.string  "vo"
  end

  create_table "filemaker_tracks", :id => false, :force => true do |t|
    t.integer "id"
    t.integer "album_id"
    t.string  "title_english"
    t.string  "title_original"
    t.string  "artist_english"
    t.string  "artist_original"
    t.string  "composer"
    t.string  "publisher"
    t.string  "distributor"
    t.string  "description"
    t.string  "info"
    t.string  "duration"
    t.string  "ending"
    t.string  "tempo_intro"
    t.string  "tempo_outro"
    t.string  "tempo"
    t.integer "track_num"
    t.text    "lyrics"
    t.string  "language"
    t.string  "gender"
    t.string  "program_type"
    t.string  "origin"
    t.string  "genre"
    t.integer "duration_min"
    t.integer "duration_sec"
  end

  create_table "genres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "genres_tracks", :id => false, :force => true do |t|
    t.integer  "genre_id"
    t.integer  "track_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "labels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "master_languages", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "master_playlist_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "masters", :force => true do |t|
    t.integer  "video_id"
    t.string   "episode_title"
    t.string   "episode_number"
    t.string   "tape_media"
    t.string   "tape_format"
    t.string   "tape_size"
    t.string   "language_track_1"
    t.string   "language_track_2"
    t.string   "language_track_3"
    t.string   "language_track_4"
    t.string   "video_subtitles_1"
    t.integer  "location"
    t.string   "time_in"
    t.string   "time_out"
    t.string   "duration"
    t.text     "synopsis"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "aspect_ratio"
    t.string   "video_subtitles_2"
    t.string   "in_playlists"
    t.boolean  "active",            :default => true
  end

  add_index "masters", ["video_id"], :name => "index_masters_on_video_id"

  create_table "movie_genres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "movie_genres_movies", :id => false, :force => true do |t|
    t.integer  "movie_genre_id"
    t.integer  "movie_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "movie_playlist_items", :force => true do |t|
    t.integer  "movie_playlist_id"
    t.integer  "movie_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "movie_playlist_items", ["movie_id"], :name => "index_movie_playlist_items_on_movie_id"
  add_index "movie_playlist_items", ["movie_playlist_id"], :name => "index_movie_playlist_items_on_movie_playlist_id"

  create_table "movie_playlist_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "movie_playlists", :force => true do |t|
    t.integer  "airline_id"
    t.date     "start_cycle"
    t.date     "end_cycle"
    t.integer  "user_id"
    t.boolean  "locked",                             :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "movie_playlist_type_id"
    t.string   "thales_schema_package_file_name"
    t.string   "thales_schema_package_content_type"
    t.integer  "thales_schema_package_file_size"
    t.datetime "thales_schema_package_updated_at"
  end

  add_index "movie_playlists", ["airline_id"], :name => "index_movie_playlists_on_airline_id"

  create_table "movie_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "movies", :force => true do |t|
    t.string   "movie_title"
    t.string   "foreign_language_title"
    t.integer  "movie_distributor_id"
    t.integer  "production_studio_id"
    t.integer  "laboratory_id"
    t.integer  "theatrical_release_year"
    t.date     "airline_release_date"
    t.date     "personal_video_date"
    t.integer  "theatrical_runtime"
    t.integer  "edited_runtime"
    t.string   "rating"
    t.text     "cast"
    t.string   "director"
    t.text     "synopsis"
    t.text     "critics_review"
    t.string   "airline_rights"
    t.date     "screener_received_date"
    t.date     "screener_destroyed_date"
    t.string   "screener_remarks"
    t.string   "screener_remarks_other"
    t.boolean  "to_delete",               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "poster_file_name"
    t.string   "poster_content_type"
    t.integer  "poster_file_size"
    t.datetime "poster_updated_at"
    t.integer  "release_versions_mask"
    t.string   "release_version"
    t.integer  "screener_remarks_mask"
    t.string   "screener_remark"
    t.boolean  "has_press_kit"
    t.boolean  "has_poster"
    t.text     "airline_countries"
    t.integer  "poster_quantity",         :default => 0
    t.text     "remarks"
    t.string   "in_playlists"
    t.text     "language_tracks"
    t.text     "language_subtitles"
    t.boolean  "active",                  :default => true
    t.string   "chinese_movie_title"
    t.text     "chinese_cast"
    t.string   "chinese_director"
    t.text     "chinese_synopsis"
    t.text     "imdb_synopsis"
    t.string   "gapp_number"
    t.integer  "movie_type_id"
  end

  add_index "movies", ["laboratory_id"], :name => "index_movies_on_laboratory_id"
  add_index "movies", ["movie_distributor_id"], :name => "index_movies_on_movie_distributor_id"
  add_index "movies", ["production_studio_id"], :name => "index_movies_on_production_studio_id"

  create_table "origins", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "programs", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "publishers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rights", :force => true do |t|
    t.string "name"
    t.string "controller"
    t.string "action"
  end

  create_table "rights_roles", :id => false, :force => true do |t|
    t.integer "right_id"
    t.integer "role_id"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "screener_playlist_items", :force => true do |t|
    t.integer  "screener_playlist_id"
    t.integer  "screener_id"
    t.integer  "position"
    t.text     "mastering"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "screener_playlist_items", ["screener_id"], :name => "index_screener_playlist_items_on_screener_id"
  add_index "screener_playlist_items", ["screener_playlist_id"], :name => "index_screener_playlist_items_on_screener_playlist_id"

  create_table "screener_playlists", :force => true do |t|
    t.integer  "airline_id"
    t.date     "start_cycle"
    t.date     "end_cycle"
    t.integer  "user_id"
    t.string   "total_runtime"
    t.string   "edit_runtime"
    t.text     "media_instruction"
    t.boolean  "locked",                 :default => false, :null => false
    t.integer  "video_playlist_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "screener_playlists", ["airline_id"], :name => "index_screener_playlists_on_airline_id"

  create_table "screeners", :force => true do |t|
    t.integer  "video_id"
    t.string   "episode_title"
    t.string   "episode_number"
    t.string   "location"
    t.string   "remarks"
    t.string   "remarks_other"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "in_playlists"
    t.boolean  "active",         :default => true
  end

  add_index "screeners", ["video_id"], :name => "index_screeners_on_video_id"

  create_table "splits", :force => true do |t|
    t.string   "name"
    t.string   "duration"
    t.integer  "more_than"
    t.integer  "less_than"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "supplier_categories", :force => true do |t|
    t.string   "name"
    t.string   "remarks"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "supplier_categories_suppliers", :id => false, :force => true do |t|
    t.integer  "supplier_id"
    t.integer  "supplier_category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "suppliers", :force => true do |t|
    t.string   "company_name"
    t.string   "contact_name_1"
    t.string   "position_1"
    t.string   "tel_1"
    t.string   "fax_1"
    t.string   "hp_1"
    t.string   "email_1"
    t.string   "contact_name_2"
    t.string   "position_2"
    t.string   "tel_2"
    t.string   "fax_2"
    t.string   "hp_2"
    t.string   "email_2"
    t.text     "address"
    t.string   "website"
    t.text     "remarks"
    t.string   "bank"
    t.text     "bank_branch"
    t.string   "bank_account"
    t.text     "aba_routing"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "beneficiary_name"
  end

  create_table "tempos", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tracks", :force => true do |t|
    t.integer  "album_id"
    t.string   "title_english"
    t.string   "title_original"
    t.string   "artist_english"
    t.string   "artist_original"
    t.string   "composer"
    t.string   "distributor"
    t.integer  "duration",        :default => 0,     :null => false
    t.string   "ending"
    t.string   "tempo_intro"
    t.string   "tempo_outro"
    t.string   "tempo"
    t.integer  "track_num"
    t.text     "lyrics"
    t.integer  "language_id"
    t.string   "gender"
    t.integer  "origin_id"
    t.boolean  "to_delete",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "genre"
    t.string   "language"
    t.string   "label"
    t.text     "musicbrainz_id"
    t.boolean  "explicit_lyrics", :default => false
    t.boolean  "mp3_exists",      :default => false
  end

  add_index "tracks", ["album_id"], :name => "index_tracks_on_album_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.integer  "login_count"
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.boolean  "enabled",           :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "perishable_token",  :default => "",   :null => false
    t.string   "email",             :default => "",   :null => false
    t.text     "roles"
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"

  create_table "video_genres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "video_parent_genre_id"
  end

  add_index "video_genres", ["video_parent_genre_id"], :name => "index_video_genres_on_video_parent_genre_id"

  create_table "video_genres_videos", :id => false, :force => true do |t|
    t.integer  "video_genre_id"
    t.integer  "video_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "video_master_playlist_items", :force => true do |t|
    t.integer  "video_master_playlist_id"
    t.integer  "master_id"
    t.integer  "position"
    t.text     "mastering"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_master_playlist_items", ["master_id"], :name => "index_video_master_playlist_items_on_master_id"
  add_index "video_master_playlist_items", ["video_master_playlist_id"], :name => "index_video_master_playlist_items_on_video_master_playlist_id"

  create_table "video_master_playlists", :force => true do |t|
    t.integer  "airline_id"
    t.date     "start_cycle"
    t.date     "end_cycle"
    t.integer  "user_id"
    t.boolean  "locked",                  :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "total_runtime"
    t.string   "edit_runtime"
    t.text     "media_instruction"
    t.integer  "master_playlist_type_id"
  end

  add_index "video_master_playlists", ["airline_id"], :name => "index_video_master_playlists_on_airline_id"

  create_table "video_parent_genres", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "video_playlist_items", :force => true do |t|
    t.integer  "video_playlist_id"
    t.integer  "video_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_playlist_items", ["video_id"], :name => "index_video_playlist_items_on_video_id"
  add_index "video_playlist_items", ["video_playlist_id"], :name => "index_video_playlist_items_on_video_playlist_id"

  create_table "video_playlist_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "video_playlists", :force => true do |t|
    t.integer  "airline_id"
    t.date     "start_cycle"
    t.date     "end_cycle"
    t.integer  "user_id"
    t.boolean  "locked",                 :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "video_playlist_type_id"
  end

  add_index "video_playlists", ["airline_id"], :name => "index_video_playlists_on_airline_id"

  create_table "videos", :force => true do |t|
    t.string   "programme_title"
    t.string   "foreign_language_title"
    t.string   "video_type"
    t.integer  "production_studio_id"
    t.integer  "laboratory_id"
    t.integer  "production_year"
    t.integer  "episodes_available"
    t.text     "synopsis"
    t.string   "trailer_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "movie_id"
    t.string   "poster_file_name"
    t.string   "poster_content_type"
    t.integer  "poster_file_size"
    t.datetime "poster_updated_at"
    t.boolean  "to_delete",               :default => false
    t.integer  "commercial_run_time_id"
    t.integer  "video_distributor_id"
    t.boolean  "on_going_series"
    t.text     "remarks"
    t.integer  "masters_count",           :default => 0
    t.integer  "screeners_count",         :default => 0
    t.string   "in_playlists"
    t.text     "language_tracks"
    t.text     "language_subtitles"
    t.boolean  "active",                  :default => true
    t.string   "chinese_programme_title"
    t.text     "chinese_synopsis"
  end

  add_index "videos", ["laboratory_id"], :name => "index_videos_on_laboratory_id"
  add_index "videos", ["production_studio_id"], :name => "index_videos_on_production_studio_id"
  add_index "videos", ["video_distributor_id"], :name => "index_videos_on_video_distributor_id"
  add_index "videos", ["video_type"], :name => "index_videos_on_video_type"

  create_table "vo_durations", :force => true do |t|
    t.string   "name"
    t.string   "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "vos", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
