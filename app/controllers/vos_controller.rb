class VosController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @vo = Vo.new
  end

  def index
    @vos = Vo.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @vo = Vo.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @vo = Vo.new params[:vo]

    respond_to do |format|
      if @vo.save
        format.html { redirect_to @vo,
                                  notice: 'VO was successfully created.' }
        format.json { render json: @vo,
                             status: :created,
                             location: @vo }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @vo.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @vo = Vo.find(params[:id])

    respond_to do |format|
      if @vo.update_attributes(params[:vo])
        flash[:notice] = 'Vo was successfully updated.'
        format.html { redirect_to(vos_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy


    @playlists = AudioPlaylist.includes(:vo).where("vos.id = ?",
                                                   params[:id])

    if  @playlists.length.zero?

      @vo = Vo.find(params[:id])
      @vo.destroy

    else
      flash[:notice] = 'VO could not be deleted,
VO is in use in a playlist'
    end

    respond_to do |format|
      format.html { redirect_to(vos_url) }
    end
  end
end