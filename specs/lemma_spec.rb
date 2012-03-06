require_relative 'spec_helper'
include SpecHelper

describe Lemma do
  describe 'routes' do
    before do
      @l = Factory :lemma
    end

    it 'has a form to create a new Lemma resource' do
      get '/lemma/new'
      last_response.body.must_include "/lemma"
    end

    it "can create a new Lemma resource" do
      post '/lemma', l = Factory.attributes_for(:lemma)
      l = Lemma.find_by_lemma(l[:lemma])
      l.must_be_kind_of Lemma
    end

    it "can show a lemma page" do
      get "/lemma/#{@l.id}"
      last_response.body.must_include @l.lemma
      last_response.body.must_include @l.translations.first.source
    end

    it "won't create an empty Lemma resource" do
      post '/lemma'
      last_response.status.must_equal 400
    end

    it "can delete a Lemma resource" do
      delete "/lemma/#{@l.id}"
      Lemma.find(@l.id).must_be_nil
    end

    it "won't delete an unknown Lemma resource" do
      count = Lemma.count
      delete "/lemma/4321"
      Lemma.count.must_equal count
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

    after do
      Lemma.all.each {|l| l.destroy}
    end
  end
end

