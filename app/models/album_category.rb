class AlbumCategory < ActiveRecord::Base
  has_many :albums

  attr_accessible :code, :name
end
