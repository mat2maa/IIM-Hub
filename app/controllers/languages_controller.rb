class LanguagesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @language = Language.new
  end

  def index
    @languages = Language.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @language = Language.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @language = Language.new params[:language]

    respond_to do |format|
      if @language.save
        format.html { redirect_to @language,
                                  notice: 'Language was successfully created.' }
        format.json { render json: @language,
                             status: :created,
                             location: @language }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @language.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @language = Language.find(params[:id])

    respond_to do |format|
      if @language.update_attributes(params[:language])
        Track.update_all(["language=?", @language.name], ["language_id=?", @language.id])

        flash[:notice] = 'Language was successfully updated.'
        format.html { redirect_to(languages_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy


    @tracks = Track.where("language_id = ?",
                          params[:id])

    if  @tracks.length.zero?

      @language = Language.find(params[:id])
      @language.destroy

    else
      flash[:notice] = 'Language could not be deleted,
language is in use in some tracks'
    end


    respond_to do |format|
      format.html { redirect_to(languages_url) }
    end
  end
end