require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "Sitemap" do
  describe 'public sitemaps' do
    before do
      FactoryGirl.create_list :multi_lemma, 7, :valid => true
    end

    it "lets everybody see the sitemap page" do
      get "/app/sitemap"
      last_response.status.must_equal 200
    end

    it "returns as many lines as there are lemmas" do
      get "/app/sitemap"
      last_response.body.count("\n").must_equal 7
    end
  end

  after do
    Lemma.delete_all
  end
end

