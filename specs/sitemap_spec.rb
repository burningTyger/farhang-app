require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "Sitemap" do
  describe 'user sitemaps' do
    before do
      u = FactoryGirl.create :user
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "plain user cant access the sitemap page" do
      get "/app/sitemap"
      last_response.status.must_equal 404
    end
  end

  describe "admin sitemaps management" do
    before do
      u = FactoryGirl.create :user, :roles => [:admin, :user]
      post '/user/login', :email => u.email, :password => 'secret'
    end

    it "lets admin not  see the sitemap page" do
      get "/app/sitemap"
      last_response.status.must_equal 404
    end
  end

  describe "root sitemaps management" do
    before do
      u = FactoryGirl.create :user, :roles => [:root, :user]
      post '/user/login', :email => u.email, :password => 'secret'
      FactoryGirl.create_list :multi_lemma, 7, :valid => true
    end

    it "lets root see the sitemap page" do
      get "/app/sitemap"
      last_response.status.must_equal 200
    end

    it "returns as many lines as there are lemmas" do
      get "/app/sitemap"
      last_response.body.count("\n").must_equal 7
    end
  end

  after do
    User.delete_all
    Lemma.delete_all
  end
end

