class AirlineRightsCountriesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index,
                       :new] do
    @airline_rights_country = AirlineRightsCountry.new
  end

  def index
    @airline_rights_countries = AirlineRightsCountry.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page.present? ? items_per_page : 100)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @airline_rights_country = AirlineRightsCountry.new params[:airline_rights_country]

    respond_to do |format|
      if @airline_rights_country.save
        format.html { redirect_to @airline_rights_country,
                                  notice: 'Airline Rights Country was successfully created.' }
        format.json { render json: @airline_rights_country,
                             status: :created,
                             location: @airline_rights_country }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @airline_rights_country.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def edit
    @airline_rights_country = AirlineRightsCountry.find(params[:id])
  end

  def update
    @airline_rights_country = AirlineRightsCountry.find(params[:id])

    respond_to do |format|
      if @airline_rights_country.update_attributes(params[:airline_rights_country])
        flash[:notice] = 'AirlineRightsCountry was successfully updated.'
        format.html { redirect_to(airline_rights_countries_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    id = params[:id]

    @airline_rights_country = AirlineRightsCountry.find(id)

    if @airline_rights_country.movies.count == 0
      @airline_rights_country.destroy
    else
      flash[:notice] = 'Airline Rights Country could not be deleted, airline_rights_country is in use by some movies'
    end

    respond_to do |format|
      format.html { redirect_to(airline_rights_countries_url) }
    end
  end
end