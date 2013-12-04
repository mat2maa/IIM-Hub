class CommercialRunTimesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @commercial_run_time = CommercialRunTime.new
  end

  def index
    @commercial_run_times = CommercialRunTime.order("minutes asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @commercial_run_time = CommercialRunTime.find(params[:id])
  end

  def new
    @commercial_run_time = CommercialRunTime.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @commercial_run_time = CommercialRunTime.new params[:commercial_run_time]

    respond_to do |format|
      if @commercial_run_time.save
        format.html { redirect_to @commercial_run_time,
                                  notice: 'Commercial Run Time was successfully created.' }
        format.json { render json: @commercial_run_time,
                             status: :created,
                             location: @commercial_run_time }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @commercial_run_time.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @commercial_run_time = CommercialRunTime.find(params[:id])

    respond_to do |format|
      if @commercial_run_time.update_attributes(params[:commercial_run_time])
        flash[:notice] = 'CommercialRunTime was successfully updated.'
        format.html { redirect_to(commercial_run_times_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]
    @videos = Video.where("commercial_run_time_id = ?",
                          id)
    if @videos.length.zero?
      @commercial_run_time = CommercialRunTime.find(id)
      @commercial_run_time.destroy
    else
      flash[:notice] = 'CommercialRunTime could not be deleted,
commercial_run_time is in use in some tracks'
    end

    @commercial_run_time.destroy

    respond_to do |format|
      format.html { redirect_to(commercial_run_times_url) }
    end
  end
end