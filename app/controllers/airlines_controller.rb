class AirlinesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @airline = Airline.new
  end

  def index
    @airlines = Airline.paginate(page: params[:page],
                                 per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @airline = Airline.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @airline }
    end
  end

  def create
    @airline = Airline.new params[:airline]

    respond_to do |format|
      if @airline.save
        format.html { redirect_to @airline,
                                  notice: 'Airline was successfully created.' }
        format.json { render json: @airline,
                             status: :created,
                             location: @airline }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @airline.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @airline = Airline.find(params[:id])

    respond_to do |format|
      if @airline.update_attributes(params[:airline])
        AudioPlaylist.update_all(["airline_cache=?", @airline.name], ["airline_id=?", @airline.id])

        flash[:notice] = 'Airline was successfully updated.'
        format.html { redirect_to(airlines_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]

    @audio_playlists = AudioPlaylist.where("airline_id = ?",
                                           id)
    @album_playlists = AlbumPlaylist.where("airline_id = ?",
                                           id)

    if @audio_playlists.length.zero? && @album_playlists.length.zero?
      @airline = Airline.find(id)
      @airline.destroy
    else
      flash[:notice] = 'Airline could not be deleted,
airline is in use in some playlists'
    end

    respond_to do |format|
      format.html { redirect_to(airlines_url) }
    end
  end
end