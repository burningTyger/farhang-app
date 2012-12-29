require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "Preferences" do
  describe 'routes' do
    before do
      u = FactoryGirl.create :user
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "plain user cant see the preferences page" do
      get "/app/preferences"
      last_response.status.must_equal 404
    end

    it "plain user cant set the preferences" do
      put "/app/preferences", :analytics => "test String"
      last_response.status.must_equal 404
    end
  end

  describe "admin preferences management" do
    before do
      u = FactoryGirl.create :user, :roles => [:admin, :user]
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "doesnt show preferences in sidebar" do
      get "/"
      last_response.body.wont_include "preferences"
    end

    it "lets admin not  see the pref page" do
      get "/app/preferences"
      last_response.status.must_equal 404
    end
  end

  describe "root preferences management" do
    before do
      u = FactoryGirl.create :user, :roles => [:root, :user]
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "lets root see the pref page" do
      get "/app/preferences"
      last_response.status.must_equal 200
    end

    it "root cat set the preferences" do
      put "/app/preferences", :analytics => "some String"
      follow_redirect!
      last_response.status.must_equal 200
    end
  end

  after do
    User.delete_all
  end
end

