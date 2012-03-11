# encoding: UTF-8
require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe "versioning" do
  before do
    @l = Factory :lemma
  end

  describe "simple" do
    it "returns the number of versions for a Lemma" do
      @l.versions_count.must_equal 1
      @l.lemma = "baden"
      @l.save
      @l.versions_count.must_equal 2
    end

    it "returns the correct value for Lemma" do
      @l.lemma = "baden"
      @l.save
      @l.reload
      @l.lemma.must_equal "baden"
    end

    it "can rollback a change to Lemma" do
      @l.lemma = "baden"
      @l.save
      @l.reload
      @l.rollback!(:first)
      @l.reload
      @l.lemma.must_equal "Wörterbuch"
    end
  end

  after do
    Lemma.delete_all
  end
end
