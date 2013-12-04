class VoDurationsController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @vo_duration = VoDuration.new
  end

  def index
    @vo_durations = VoDuration.order("duration")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @vo_duration = VoDuration.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @vo_duration }
    end
  end

  def create
    @vo_duration = VoDuration.new params[:vo_duration]

    respond_to do |format|
      if @vo_duration.save
        format.html { redirect_to @vo_duration,
                                  notice: 'VO Duration was successfully created.' }
        format.json { render json: @vo_duration,
                             status: :created,
                             location: @vo_duration }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @vo_duration.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @vo_duration = VoDuration.find(params[:id])

    respond_to do |format|
      if @vo_duration.update_attributes(params[:vo_duration])
        flash[:notice] = 'VoDuration was successfully updated.'
        format.html { redirect_to(vo_durations_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    @vo_duration = VoDuration.find(params[:id])
    @vo_duration.destroy

    respond_to do |format|
      format.html { redirect_to(vo_durations_url) }
    end
  end
end