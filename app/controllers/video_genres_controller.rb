class VideoGenresController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @video_genre = VideoGenre.new
  end

  def index
    @video_genres = VideoGenre.includes(:video_parent_genre)
    .order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @video_genre = VideoGenre.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @video_genre = VideoGenre.new params[:video_genre]

    respond_to do |format|
      if @video_genre.save
        format.html { redirect_to @video_genre,
                                  notice: 'Video Genre was successfully created.' }
        format.json { render json: @video_genre,
                             status: :created,
                             location: @video_genre }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @video_genre.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @video_genre = VideoGenre.find(params[:id])

    respond_to do |format|
      if @video_genre.update_attributes(params[:video_genre])
        #Video.update_all(["video_genre_cache=?",@video_genre.name],["video_genre_id=?",@video_genre.id] )
        flash[:notice] = 'VideoGenre was successfully updated.'
        format.html { redirect_to(video_genres_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]
    @videos = Video.includes(:video_genres).where("video_genres_videos.video_genre_id = ?",
                                                  id)
    if @videos.length.zero?
      @video_genre = VideoGenre.find(id)
      @video_genre.destroy
    else
      flash[:notice] = 'Video genre could not be deleted, video genre is in use by some videos'
    end

    respond_to do |format|
      format.html { redirect_to(video_genres_url) }
    end
  end
end