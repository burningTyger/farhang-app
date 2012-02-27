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

    it "can modify a Lemma resource" do
      put "/lemma/#{@l.id}", :lemma => "test"
      Lemma.find(@l.id).lemma.must_equal "test"
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

