class VideoParentGenresController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @video_parent_genre = VideoParentGenre.new
  end

  def index
    @video_parent_genres = VideoParentGenre.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @video_parent_genre = VideoParentGenre.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @video_parent_genre = VideoParentGenre.new params[:video_parent_genre]

    respond_to do |format|
      if @video_parent_genre.save
        format.html { redirect_to @video_parent_genre,
                                  notice: 'Video Parent Genre was successfully created.' }
        format.json { render json: @video_parent_genre,
                             status: :created,
                             location: @video_parent_genre }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @video_parent_genre.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @video_parent_genre = VideoParentGenre.find(params[:id])

    respond_to do |format|
      if @video_parent_genre.update_attributes(params[:video_parent_genre])
        #Movie.update_all(["video_parent_genre_cache=?",@video_parent_genre.name],["video_parent_genre_id=?",@video_parent_genre.id] )
        flash[:notice] = 'VideoParentGenre was successfully updated.'
        format.html { redirect_to(video_parent_genres_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]
    @videos = VideoGenre.where("video_parent_genre_id = ?",
                               id)
    if @videos.length.zero?
      @video_genre = VideoParentGenre.find(id)
      @video_genre.destroy
    else
      flash[:notice] = 'Genre could not be deleted as it contains subcategories'
    end

    respond_to do |format|
      format.html { redirect_to(video_parent_genres_url) }
    end
  end
end