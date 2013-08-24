# encoding: UTF-8
require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe Lemma do
  before do
    @l = FactoryGirl.create :lemma
  end

  describe 'anonymous access' do
    it 'has not a form to create a new Lemma resource' do
      get '/lemma/new'
      last_response.status.must_equal 404
    end

    it "can't create a new Lemma resource" do
      post '/lemma', l = FactoryGirl.attributes_for(:lemma, :lemma => "Brot")
      l = Lemma.find_by_lemma(l[:lemma]).must_be_nil
      last_response.status.must_equal 404
    end

    it "can show a lemma page, but not a form" do
      get "/lemma/#{@l.id}"
      follow_redirect!
      last_response.body.must_include @l.lemma
      last_response.body.must_include @l.translations.first.source
      last_response.body.wont_include "translation[0]"
    end

    it "can't delete a Lemma resource" do
      delete "/lemma/#{@l.id}"
      Lemma.find(@l.id).must_equal @l
    end

    it "can't modify a lemma of a Lemma resource" do
      put "/lemma/#{@l.id}", :lemma => "test"
      last_response.status.must_equal 404
    end

    it "shows a slugged page" do
      get "/l/#{@l.slug}"
      last_response.body.must_include @l.lemma
      last_response.body.must_include @l.translations.first.source
      last_response.body.wont_include "translation[0]"
    end
  end

  describe 'logged in' do
    before do
      @u = FactoryGirl.create :user
      post '/user/login', :email => @u.email, :password => 'secret'
    end

    it 'has a form to create a new Lemma resource' do
      get '/lemma/new'
      last_response.body.must_include "/lemma"
    end

    it "can create a new Lemma resource" do
      post '/lemma', l = FactoryGirl.attributes_for(:lemma)
      l = Lemma.find_by_lemma(l[:lemma])
      l.must_be_kind_of Lemma
    end

    it "can show a lemma page" do
      get "/lemma/#{@l.id}"
      follow_redirect!
      last_response.body.must_include @l.lemma
      last_response.body.must_include @l.translations.first.source
    end

    it "can't delete a Lemma resource as regular user" do
      count = Lemma.count
      delete "/lemma/#{@l.id}"
      count.must_equal Lemma.count
    end

    it "won't delete an unknown Lemma resource" do
      count = Lemma.count
      delete "/lemma/4321"
      Lemma.count.must_equal count
    end

    it "can modify the lemma of a Lemma resource" do
      put "/lemma/#{@l.id}", :lemma => "test"
      follow_redirect!
      last_request.env["PATH_INFO"].must_equal "/lemma/#{@l.id}/preview"
    end

    it "can modify the lemma of a Lemma resource" do
      put "/lemma/#{@l.id}", :lemma => "test"
      follow_redirect!
      last_response.body.must_include "test"
    end

    it "can modify the translation of a Lemma" do
      put "/lemma/#{@l.id}?lemma=test&translations%5B0%5D%5Bsource%5D=s0&translations%5B0%5D%5Btarget%5D=t0&translations%5B1%5D%5Bsource%5D=s1&translations%5B1%5D%5Btarget%5D=t1"
      follow_redirect!
      last_response.body.must_include "s0"
    end

    it "will accept a translation without a lemma in Lemma" do
      put "/lemma/#{@l.id}?translations%5B0%5D%5Bsource%5D=s0&translations%5B0%5D%5Btarget%5D=t0&translations%5B1%5D%5Bsource%5D=s1&translations%5B1%5D%5Btarget%5D=t1"
      follow_redirect!
      last_response.status.must_equal 200
      last_response.body.must_include "s0"
    end

    it "will accept a modification with an invalid translation but not save the invalid part" do
      put "/lemma/#{@l.id}?translations%5B0%5D%5Btarget%5D=t0&translations%5B1%5D%5Bsource%5D=s1&translations%5B1%5D%5Btarget%5D=t1"
      follow_redirect!
      last_response.body.must_include "s1"
      last_response.body.wont_include "s0"
    end

    it "wont modify an unknown Lemma resource" do
      put "/lemma/1234", :lemma => "Nelly"
      Lemma.find("1234").must_be_nil
    end

    it "will let user create a valid edit of Lemma" do
      put "/lemma/#{@l.id}", :lemma => "test"
      follow_redirect!
      last_response.body.must_include "test"
      @l.reload
      @l.valid.must_equal false
      @l.version_at(:latest).updater_id.must_equal @u.id.to_param
    end
  end

  describe 'logged in as admin' do
    before do
      @ua = FactoryGirl.create :user, :roles => [:user, :admin]
      post '/user/login', :email => @ua.email, :password => 'secret'
    end

    it "will let admin create a valid edit of Lemma" do
      put "/lemma/#{@l.id}", :lemma => "test"
      follow_redirect!
      last_response.body.must_include "test"
      @l.reload
      @l.valid.must_equal true
      @l.version_at(:latest).updater_id.must_equal @ua.id.to_param
    end

    it "will let admin delete a Lemma" do
      count = Lemma.count
      delete "/lemma/#{@l.id}"
      Lemma.count.must_equal count-1
    end

    it "will let admin see the validation page" do
      get "/lemma/validation"
      last_response.status.must_equal 200
    end

    it "will let admin see the users page" do
      get "/users"
      last_response.status.must_equal 200
    end

    it "will let admin create sluggable multiword entry" do
      l = FactoryGirl.create :lemma, :lemma => "funny dog"
      l.slug.must_equal "funny-dog"
    end

    it "will let admin create sluggable ascii entry" do
      l = FactoryGirl.create :lemma, :lemma => "funny"
      l.slug.must_equal "funny"
    end

    it "will let admin create sluggable utf-8 entry" do
      l = FactoryGirl.create :lemma, :lemma => "löäüßet"
      l.slug.must_equal "loeaeuesset"
    end
  end

  describe 'logged in as admin with validation action' do
    before do
      uu = FactoryGirl.create :user
      post '/user/login', :email => uu.email, :password => 'secret'
      put "/lemma/#{@l.id}", :lemma => 'test'
      ua = FactoryGirl.create :user, :roles => [:user, :admin]
      post '/user/login', :email => ua.email, :password => 'secret'
    end

    it "will let the admin see an invalid Lemma" do
      get '/lemma/validation'
      last_response.body.must_include 'Wörterbuch'
      last_response.body.must_include 'test'
    end

    it "will let the admin validate a Lemma" do
      patch "/lemma/#{@l.id}/valid", :valid => true
      get '/lemma/validation'
      last_response.body.wont_include 'Wörterbuch'
      last_response.body.wont_include 'test'
    end

    it "will let the admin reject a validation" do
      get "/lemma/#{@l.id}"
      follow_redirect!
      last_response.body.must_include 'test'
      patch "/lemma/#{@l.id}/valid", :valid => false
      get "/lemma/#{@l.id}"
      follow_redirect!
      last_response.body.must_include 'Wörterbuch'
      last_response.body.wont_include 'test'
    end

  end

  after do
    Lemma.delete_all
    User.delete_all
  end
end

