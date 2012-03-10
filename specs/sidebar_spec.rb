# encoding: UTF-8
require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "sidebar" do
  before do
    Factory :lemma
  end

  describe "anonymous" do
    it "returns the homepage for unsigned user" do
      get '/'
      last_response.body.must_include 'Anmelden'
      last_response.body.wont_include 'Abmelden'
    end
  end

  describe "common user" do
    before do
      u = Factory :user
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "returns the homepage for common user" do
      get '/'
      last_response.body.must_include 'Abmelden'
      last_response.body.wont_include 'Bestätigen'
    end

    after do
      User.delete_all
    end
  end

  describe "admin user" do
    before do
      u = Factory :user, :roles => [:user, :admin]
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "returns the homepage for admin user" do
      get '/'
      last_response.body.must_include 'Bestätigen'
      #last_response.body.wont_include 'Übersicht'
    end

    after do
      User.delete_all
    end
  end

  describe "root user" do
    before do
      u = Factory :user, :roles => [:user, :root]
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "returns the homepage for root user" do
      get '/'
      last_response.body.must_include 'Bestätigen'
      last_response.body.must_include 'Übersicht'
    end

    after do
      User.delete_all
    end
  end

  after do
    Lemma.delete_all
  end
end

