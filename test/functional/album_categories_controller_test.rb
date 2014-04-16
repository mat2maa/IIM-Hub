require 'test_helper'

class AlbumCategoriesControllerTest < ActionController::TestCase
  setup do
    @album_category = album_categories(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:album_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create album_category" do
    assert_difference('AlbumCategory.count') do
      post :create, album_category: { code: @album_category.code, name: @album_category.name }
    end

    assert_redirected_to album_category_path(assigns(:album_category))
  end

  test "should show album_category" do
    get :show, id: @album_category
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @album_category
    assert_response :success
  end

  test "should update album_category" do
    put :update, id: @album_category, album_category: { code: @album_category.code, name: @album_category.name }
    assert_redirected_to album_category_path(assigns(:album_category))
  end

  test "should destroy album_category" do
    assert_difference('AlbumCategory.count', -1) do
      delete :destroy, id: @album_category
    end

    assert_redirected_to album_categories_path
  end
end
