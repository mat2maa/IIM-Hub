class LabelsController < ApplicationController
  before_filter :require_user
  cache_sweeper :label_sweeper,
                only: [:new,
                       :create,
                       :update,
                       :destroy]
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @label = Label.new
  end

  def index
    @labels = Label.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @label = Label.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @label = Label.new params[:label]

    respond_to do |format|
      if @label.save
        format.html { redirect_to @label,
                                  notice: 'Label was successfully created.' }
        format.json { render json: @label,
                             status: :created,
                             location: @label }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @label.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @label = Label.find(params[:id])

    respond_to do |format|
      if @label.update_attributes(params[:label])
        flash[:notice] = 'Label was successfully updated.'
        format.html { redirect_to(labels_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy


    @albums = Album.where("label_id = ?",
                          params[:id])

    if  @albums.length.zero?

      @label = Label.find(params[:id])
      @label.destroy

    else
      flash[:notice] = 'Label could not be deleted,
label is in use in some albums or tracks'
    end


    respond_to do |format|
      format.html { redirect_to(labels_url) }
    end
  end
end