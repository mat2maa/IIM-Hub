# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all # include all helpers,all the time
  helper_method :current_user_session,
                :current_user,
                :logged_in?

  before_filter :get_movie_distributors
  before_filter :get_video_distributors
  before_filter :get_laboratories
  before_filter :get_production_studios

  def associates_id
    "imagesinmotio-20"
  end

  def key_id
    "1N2N5SNXQGQPXN6T9CR2"
  end

  def verify_iim_app(app_id)
    salt = Time.zone.now.day * 381237 + 87219
    app_id==Settings.iim_app_id + salt.to_s
  end

  def url_exists?(url)
    uri = URI.parse(url)
    http_conn = Net::HTTP.new(uri.host,
                              uri.port)
    resp,
        data = http_conn.head(uri.path,
                              nil)
    resp.code == "200"
  end

  # convert a collection of videos or movies into an array of their ids
  def collection_to_id_array(col)
    ids = Array.new
    col.each do |i|
      ids << i.id
    end
    ids
  end

  def get_movie_distributors
    @movie_distributors = Supplier.connection.execute("SELECT `suppliers`.`company_name` AS t0_r1,
`suppliers`.`id` AS t0_r0 FROM `suppliers` LEFT OUTER JOIN `supplier_categories_suppliers` ON
`supplier_categories_suppliers`.`supplier_id` = `suppliers`.`id` LEFT OUTER JOIN `supplier_categories` ON
`supplier_categories`.`id` = `supplier_categories_suppliers`.`supplier_category_id` WHERE `supplier_categories`
.`name` = 'Movie Distributors' ORDER BY company_name asc").to_a
  end

  def get_video_distributors
    @video_distributors = Supplier.connection.execute("SELECT `suppliers`.`company_name` AS t0_r1,
`suppliers`.`id` AS t0_r0 FROM `suppliers` LEFT OUTER JOIN `supplier_categories_suppliers` ON
`supplier_categories_suppliers`.`supplier_id` = `suppliers`.`id` LEFT OUTER JOIN `supplier_categories` ON
`supplier_categories`.`id` = `supplier_categories_suppliers`.`supplier_category_id` WHERE `supplier_categories`
.`name` = 'Video Distributors' ORDER BY company_name asc").to_a
  end

  def get_laboratories
    @laboratories = Supplier.connection.execute("SELECT `suppliers`.`company_name` AS t0_r1,
`suppliers`.`id` AS t0_r0 FROM `suppliers` LEFT OUTER JOIN `supplier_categories_suppliers` ON
`supplier_categories_suppliers`.`supplier_id` = `suppliers`.`id` LEFT OUTER JOIN `supplier_categories` ON
`supplier_categories`.`id` = `supplier_categories_suppliers`.`supplier_category_id` WHERE `supplier_categories`
.`name` = 'Laboratories' ORDER BY company_name asc").to_a
  end

  def get_production_studios
    @production_studios = Supplier.connection.execute("SELECT `suppliers`.`company_name` AS t0_r1,
`suppliers`.`id` AS t0_r0 FROM `suppliers` LEFT OUTER JOIN `supplier_categories_suppliers` ON
`supplier_categories_suppliers`.`supplier_id` = `suppliers`.`id` LEFT OUTER JOIN `supplier_categories` ON
`supplier_categories`.`id` = `supplier_categories_suppliers`.`supplier_category_id` WHERE `supplier_categories`
.`name` = 'Production Studios' ORDER BY company_name asc").to_a
  end

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
    Authorization.current_user = @current_user
  end

  def logged_in?
    !!current_user
  end

  def require_user
    unless current_user
      store_location
      #flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_path
      return false
    end
  end

  def require_http_auth_user
    authenticate_or_request_with_http_basic do |username, password|
      if user = User.find_by_login(username)
        user.valid_password?(password)
      else
        false
      end
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def duration ms
    if !ms.nil?

      sec = ms/1000

      min = sec/60

      sec = sec%60

      if sec < 10
        sec = "0#{sec}"
      end
      if sec == 0
        sec = "00"
      end
      if min == 0
        min = "0"
      end

      t = "#{min}:#{sec}"
    else
      t = "0:00"
    end
    t
  end

  private
  def items_per_page
    if params[:per_page]
      session[:items_per_page] = params[:per_page]
    end
    session[:items_per_page]
  end

end
