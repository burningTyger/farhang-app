# encoding: UTF-8
require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "routes" do
  describe "home route" do
    before do
      @u = FactoryGirl.create :user
    end

    it "returns the homepage for unsigned user" do
      get '/'
      last_response.body.must_include 'Farhang'
    end

    it "returns a 302, ie redirect to search upon false address" do
      get '/ferf'
      last_response.status.must_equal 302
    end

    it "returns the dashboard for signed user" do
      post '/user/login', :email => @u.email, :password => 'secret'
      get '/'
      last_response.body.must_include 'Einträge'
    end
  end

  describe "search routes" do
    before do
      FactoryGirl.create :lemma, :lemma  => 'Apfel'
    end

    it "gets and finds a url search" do
      get '/search/Apfel'
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
      get '/search/apfel'
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
    end

    it "gets and finds a params search" do
      get '/app/search', :term => 'Apfel'
      follow_redirect!
      get '/app/search', :term => 'apfel'
      follow_redirect!
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
    end

    it "can find a search term with parens in it" do
      FactoryGirl.create :lemma, :lemma => 'ca (*:cirka)'
      get '/app/search', :term => 'ca%20(*:cirka)'
      follow_redirect!
      last_response.body.must_include 'cirka'
    end

    it "returns a valid json file for autocomplete" do
      get '/search/autocomplete.json?term=ap'
      last_response.body.must_equal '["Apfel"]'
    end

    after do
      Lemma.delete_all
    end
  end

  describe "ping route" do
    it "returns a 200 on /app/ping" do
      get '/app/ping'
      last_response.status.must_equal 200
    end

    it "returns a sitemap" do
      get '/app/sitemap.txt'
      last_response['Content-Type'].must_equal 'text/html;charset=utf-8'
    end
  end
end

