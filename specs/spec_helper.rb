# encoding: UTF-8
ENV['RACK_ENV'] = 'testing'
gem "minitest"
require 'minitest/autorun'
require 'mongo_mapper'
require 'rack/test'
require 'factory_girl'
require 'purdytest'
require_relative 'factories'
require_relative '../farhang'

module SpecHelper
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end

  def session
    last_request.env['rack.session']
  end

  def setup

  end

end
