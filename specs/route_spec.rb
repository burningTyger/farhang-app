# encoding: UTF-8
require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "routes" do
  describe "home route" do
    before do
      @u = Factory :user
    end

    it "returns the homepage for unsigned user" do
      get '/'
      last_response.body.must_include 'Farhang'
    end

    it "returns a 404 upon false address" do
      get '/ferf'
      last_response.status.must_equal 404
    end

    it "returns the dashboard for signed user" do
      post '/user/login', :email => @u.email, :password => 'secret'
      get '/'
      last_response.body.must_include 'Einträge'
    end
  end

  describe "search routes" do
    it "gets and finds a url search" do
      Factory(:lemma, :lemma  => 'Apfel')
      get '/search/Apfel'
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
      get '/search/apfel'
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
    end

    it "gets and finds a params search" do
      Factory(:lemma, :lemma  => 'Apfel')
      get '/search', :term => 'Apfel'
      follow_redirect!
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
      get '/search', :term => 'apfel'
      follow_redirect!
      last_response.body.must_include 'Apfel'
      last_response.body.wont_include 'Augapfel'
    end

    it "can find a search term with parens in it" do
      Factory(:lemma, :lemma => 'ca (*:cirka)')
      get '/search', :term => 'ca%20(*:cirka)'
      follow_redirect!
      last_response.body.must_include 'cirka'
    end

    after do
      Lemma.delete_all
    end
  end
end

