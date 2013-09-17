class AddMoviesIndexes < ActiveRecord::Migration
  def up
    add_index :movies, :movie_type_id
    add_index :movie_genres_movies, [:movie_genre_id, :movie_id]
  end

  def down
    remove_index :movies, :column => :movie_type_id
    remove_index :movie_genres_movies, :column => [:movie_genre_id, :movie_id]
  end
end
