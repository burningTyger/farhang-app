# encoding: UTF-8
ENV['RACK_ENV'] = 'test'
require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require 'minitest/autorun'
require 'rack/test'
#require 'factory_girl'
#require 'database_cleaner'

#require_relative 'factories'
require_relative '../farhang'

module TestHelper
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
  
  def setup

  end

  def teardown
#    DatabaseCleaner.clean
  end
  
  def login
  end
  
  def logout
  end
  
  def content

  end
end
