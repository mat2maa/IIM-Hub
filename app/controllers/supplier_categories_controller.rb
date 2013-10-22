class SupplierCategoriesController < ApplicationController
  before_filter :require_user
  filter_access_to :all

  before_filter only: [:index, :new] do
    @category = SupplierCategory.new
  end

  def index
    @categories = SupplierCategory.order("name asc")
    .paginate(page: params[:page],
              per_page: items_per_page)
    respond_to do |format|
      format.html # index.html.erb
    end
  end


  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml { render xml: @category }
    end
  end

  def create
    @category = SupplierCategory.new params[:supplier_category]

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category,
                                  notice: 'Category was successfully created.' }
        format.json { render json: @category,
                             status: :created,
                             location: @category }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @category.errors,
                             status: :unprocessable_entity }
        format.js
      end
    end
  end

  def edit
    @category = SupplierCategory.find(params[:id])
  end

  def update
    @category = SupplierCategory.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:supplier_category])
        flash[:notice] = 'Category was successfully updated.'
        format.html { redirect_to(supplier_categories_path) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy

    count = Supplier.where("supplier_category_id=?",
                           params[:id])
    .count(from: "supplier_categories_suppliers")

    if count.zero?

      @category = SupplierCategory.find(params[:id])
      @category.destroy

    else
      flash[:notice] = 'Category could not be deleted, category is in use in some suppliers'
    end

    respond_to do |format|
      format.html { redirect_to(supplier_categories_url) }
    end
  end
end