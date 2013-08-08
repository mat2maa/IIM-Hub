module ActiveRecordExtension

  extend ActiveSupport::Concern

  def next
    self.class.where('id > ?', self.id).order('id ASC').first
  end

  def previous
    self.class.where('id < ?', self.id).order('id DESC').first
  end

end

# include the extension
ActiveRecord::Base.send(:include, ActiveRecordExtension)