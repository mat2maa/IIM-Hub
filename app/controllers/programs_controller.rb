class ProgramsController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @program = Program.new
  end

  def index
    @programs = Program.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def edit
    @program = Program.find(params[:id])
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @program = Program.new params[:program]

    respond_to do |format|
      if @program.save
        format.html { redirect_to @program,
                                  notice: 'Program was successfully created.' }
        format.json { render json: @program,
                             status: :created,
                             location: @program }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @program.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def update
    @program = Program.find(params[:id])

    respond_to do |format|
      if @program.update_attributes(params[:program])
        AudioPlaylist.update_all(["program_cache=?", @program.name], ["program_id=?", @program.id])
        flash[:notice] = 'Program was successfully updated.'
        format.html { redirect_to(programs_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]
    @audio_playlists = AudioPlaylist.where("program_id = ?",
                                           id)
    if @audio_playlists.length.zero?
      @program = Program.find(id)
      @program.destroy
    else
      flash[:notice] = 'Program could not be deleted,
program is in use in some tracks'
    end

    respond_to do |format|
      format.html { redirect_to(programs_url) }
    end
  end
end