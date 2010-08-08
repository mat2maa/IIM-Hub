require 'test/unit'
RAILS_ROOT = File.dirname(__FILE__) + '/../../../../'
require File.dirname(__FILE__) + '/../lib/authorization.rb'
require File.dirname(__FILE__) + '/../lib/in_controller.rb'

unless defined?(ActiveRecord)
  if File.directory? RAILS_ROOT + 'config'
    puts 'using config/boot.rb'
    ENV['RAILS_ENV'] = 'test'
    require File.join(RAILS_ROOT, 'config', 'boot.rb')
  else
    # simply use installed gems if available
    puts 'using rubygems'
    require 'rubygems'
    gem 'actionpack'; gem 'activerecord'; gem 'activesupport'
  end

  %w(action_pack action_controller active_record active_support).each {|f| require f}
end

class MockDataObject
  def initialize (attrs = {})
    attrs.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      self.class.class_eval do
        attr_reader key
      end
    end
  end
  
  def self.table_name
    "mocks"
  end
end

class MockUser < MockDataObject
  def initialize (*roles)
    options = roles.last.is_a?(::Hash) ? roles.pop : {}
    super(options.merge(:roles => roles))
  end
end

class MocksController < ActionController::Base
  attr_accessor :current_user
  attr_writer :authorization_engine
  
  def authorized?
    !@before_filter_chain_aborted
  end
  
  def self.define_action_methods (*methods)
    methods.each do |method|
      define_method method do
        render :text => 'nothing'
      end
    end
  end
  
  def logger (*args)
    Class.new do 
      def warn(*args)
        #p args
      end
      alias_method :info, :warn
      def warn?; end
      alias_method :info?, :warn?
    end.new
  end
end

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end
ActionController::Base.send :include, Authorization::AuthorizationInController
require "action_controller/test_process"

class Test::Unit::TestCase
  def request! (user, action, reader, params = {})
    action = action.to_sym if action.is_a?(String)
    @controller.current_user = user
    @controller.authorization_engine = Authorization::Engine.new(reader)
    
    (params.delete(:clear) || []).each do |var|
      @controller.instance_variable_set(var, nil)
    end
    get action, params
  end
end