Iim::Application.routes.draw do


  resources :movie_playlist_types


  resources :movie_types


  root to: "dashboard#index"

  # probably refers to "my account", we'll need to handle it differently
  # resource :account, :controller => "users"


  match "/account/edit_own_password" => "users#edit_own_password", as: :change_password
  match "/logout" => "user_sessions#destroy", as: :logout
  match "/add_track_to_playlist/:id" => "audio_playlists#add_track_to_playlist", as: :add_track_to_playlist
  match "/add_album_to_playlist/:id" => "album_playlists#add_album_to_playlist", as: :add_album_to_playlist
  match "/add_movie_to_playlist/:id" => "movie_playlists#add_movie_to_playlist", as: :add_movie_to_playlist
  match "/add_video_to_playlist/:id" => "video_playlists#add_video_to_playlist", as: :add_video_to_playlist
  match "/add_video_master_to_playlist/:id" => "video_master_playlists#add_video_master_to_playlist", as: :add_video_master_to_playlist
  match "/add_screener_to_playlist/:id" => "screener_playlists#add_screener_to_playlist", as: :add_screener_to_playlist

  match "/add_review_to_movie/:id" => "movies#add_review_to_movie", as: :add_review_to_movie

  match "/download_audio_playlist/:id" => "audio_playlists#download_audio_playlist", as: :download_audio_playlist
  match "/poll_download_data/:id" => "audio_playlists#poll_download_data", as: :poll_download_data
  match "/download_playlist_zip/:id" => "audio_playlists#download_playlist_zip", as: :download_playlist_zip

  match "/download_album_mp3/:id" => "album_playlists#download_mp3", as: :download_album_tracks_mp3
  match "/edit_album_playlist_synopsis/:id" => "album_playlists#edit_synopsis", as: :edit_album_playlist_synopsis
  match "/export_by_airline" => "album_playlists#export_by_airline", as: :export_by_airline
  match "/view_splits" => "audio_playlists#splits", as: :view_splits

#  match "/movie_playlists/print/:id" => "movie_playlists#print", as: :print_movie_playlist
  match "/movie_playlists/show_chinese/:id" => "movie_playlists#show_chinese", as: :show_chinese
  match "/movie_playlists/export_to_excel/:id" => "movie_playlists#export_to_excel", as: :export_to_excel
  match "/movie_playlists/download_thales_schema_package/:id" => "movie_playlists#download_thales_schema_package",
                                                                 as: :download_thales_schema_package

  match "/audio_playlists/print/:id" => "audio_playlists#print", as: :print_audio_playlist
  match "/audio_playlists/export_to_excel/:id" => "audio_playlists#export_to_excel", as: :export_to_excel
  match "/audio_playlists/find_via_json/:id" => "audio_playlists#find_via_json", as: :find_via_json

  match "/album_playlists/print/:id" => "album_playlists#print", as: :print_album_playlist
  match "/album_playlists/export_to_excel/:id" => "album_playlists#export_to_excel", as: :export_to_excel

  match "/albums/amazon_cd_covers" => "albums#amazon_cd_covers", as: :amazon_cd_covers
  match "/albums/create_from_json" => "albums#create_from_json", as: :create_album_from_json

#  match "/video_playlists/print/:id" => "video_playlists#print", as: :print_video_playlist
  match "/video_playlists/show_chinese/:id" => "video_playlists#show_chinese", as: :show_chinese
  match "/video_playlists/export_to_excel/:id" => "video_playlists#export_to_excel", as: :export_to_excel

#  match "/video_master_playlists/print/:id" => "video_master_playlists#print", as: :print_video_master_playlist
  match "/video_master_playlists/show_chinese/:id" => "video_master_playlists#show_chinese", as: :show_chinese
  match "/video_master_playlists/export_to_excel/:id" => "video_master_playlists#export_to_excel", as: :export_to_excel

#  match "/screener_playlists/print/:id" => "screener_playlists#print", as: :print_screener_playlist
  match "/screener_playlists/show_chinese/:id" => "screener_playlists#show_chinese", as: :show_chinese
  match "/screener_playlists/export_to_excel/:id" => "screener_playlists#export_to_excel", as: :export_to_excel

  match "/movies/update_date/:id" => "movies#update_date", as: :update_date

  match "/albums/add_track" => "albums#add_track", as: :add_track

  match "/import_album/find_release" => "import_album#find_release", as: :find_release
  match "/import_album/import_release" => "import_album#import_release", as: :import_release

  match "/tracks/sort" => "tracks#sort", as: :sort_track
  match "/audio_playlist_tracks/sort" => "audio_playlist_tracks#sort", as: :sort_audio_playlist
  match "/album_playlist_items/sort" => "album_playlist_items#sort", as: :sort_album_playlist
  match "/movie_playlist_items/sort" => "movie_playlist_items#sort", as: :sort_movie_playlist
  match "/video_playlist_items/sort" => "video_playlist_items#sort", as: :sort_video_playlist
  match "/video_master_playlist_items/sort" => "video_master_playlist_items#sort", as: :sort_video_master_playlist
  match "/screener_playlist_items/sort" => "screener_playlist_items#sort", as: :sort_screener_playlist

  match "/albums/restore/:id" => "albums#restore", as: :restore_album
  match "/movies/restore/:id" => "movies#restore", as: :restore_movie
  match "/tracks/restore/:id" => "tracks#restore", as: :restore_track
  match "/videos/restore/:id" => "videos#restore", as: :restore_video

  match "/delayed_job" => DelayedJobWeb, :anchor => false

  resources :users do
    member do
      post 'enable'
      post 'disable'
    end
  end

  resources :password_resets

  resources :audio_playlists do
    member do
      post 'duplicate'
      post 'lock'
      post 'unlock'
      post 'add_track'

      get 'zip', action: 'mp3', as: 'audio_playlist_zip'

    end
    collection do
      post 'add_multiple_tracks'
    end
  end

  resource :user_session
  resources :roles
  resources :rights
  resources :splits
  resources :vo_durations
  resources :airlines
  resources :programs
  resources :genres
  resources :labels
  resources :audio_playlist_tracks

  resources :album_playlists do
    member do
      post 'duplicate'
      post 'lock'
      post 'unlock'
      post 'add_album'
    end
    collection do
      post 'add_multiple_albums'
      post 'export_albums_programmed_per_airline_to_excel'
    end
  end

  resources :album_playlist_items

  resources :movie_playlists do
    member do
      post 'duplicate'
      post 'lock'
      post 'unlock'
      post 'add_movie'
    end
    collection do
      post 'add_multiple_movies'
    end
  end

  resources :movie_playlist_items

  resources :video_playlists do
    member do
      post 'duplicate'
      post 'lock'
      post 'unlock'
      post 'add_video'
    end
    collection do
      post 'add_multiple_videos'
    end
  end

  resources :video_playlist_items

  resources :video_master_playlists do
    member do
      post 'duplicate'
      post 'lock'
      post 'unlock'
      post 'add_video_master'
    end
    collection do
      post 'add_multiple_masters'
    end
  end

  resources :video_master_playlist_items

  resources :screener_playlists do
    member do
      post 'duplicate'
      post 'lock'
      post 'unlock'
      post 'add_screener'
    end
    collection do
      post 'add_multiple_screeners'
    end
  end

  resources :screener_playlist_items

  resources :import_album do
    member do
      post 'itunes_import'
    end
    collection do
      post 'find_albums'
      post 'cddb_import'
      post 'update_album_mp3_exists'
    end
  end

  resources :publishers
  resources :vos
  resources :settings

  resources :albums do
    member do
      get 'show_tracks'
      get 'show_genre'
      get 'show_synopsis'
      get 'show_tracks_translation'
      get 'show_playlists'
    end
  end

  resources :tracks do
    member do
      get 'show_genre'
      get 'show_lyrics_form'
      get 'show_playlists'
    end
  end

  resources :languages
  resources :master_languages
  resources :origins
  resources :categories
  resources :supplier_categories
  resources :find_albums
  resources :find_songs
  resources :movies
  resources :suppliers
  resources :airline_rights_countries
  resources :movie_genres
  resources :video_genres
  resources :video_parent_genres
  resources :movies_settings
  resources :videos
  resources :commercial_run_times
  resources :video_playlist_types
  resources :master_playlist_types

  resources :masters do
    member do
      post 'duplicate'
    end
  end

  resources :screeners do
    member do
      post 'duplicate'
    end
  end



  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
