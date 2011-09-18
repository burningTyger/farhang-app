require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'test_helper'

class A_RoutingTest < MiniTest::Unit::TestCase
  include TestHelper

  def test_it_says_ok_on_root
    get '/'
    assert last_response.body.include?('farhang')
  end

  def test_fail_address
    get '/sdsds'
    assert_equal 404, last_response.status
  end

  def test_css
    get '/assets/css/layout.css'
    assert last_response.body.include?('helvetica')
  end

  def test_js
    get '/assets/js/application.js'
    assert last_response.body.include?('$(document).ready')
  end
  
  def test_get_search_ok
    get '/search/Apfel'
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
    
    get '/search/apfel'
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
  end

  def test_post_search_ok
    post '/search?term=Apfel'
    follow_redirect!
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
    
    post '/search?term=apfel'
    follow_redirect!
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
  end

  def test_show_lemma_id
    l = Factory(:lemma)
    get "/lemma/#{l.id}"
    assert last_response.body.include?('das_schweigende_lemma')
    l.destroy
  end

  def test_show_translation_id
    t = Factory(:translation)
    get "/translation/#{t.id}"
    assert last_response.body.include?('warum nicht?')
    t.destroy
  end
  
  def test_change_many_translation_lemma
    l = Factory(:lemma)
    t = Factory(:translation)
    put "/translation/#{t.id}/lemmas?lemma=#{l.lemma}"
    assert last_response.body.include?('true')
    l.destroy
    t.destroy
  end
  
  def test_autocomplete
    get '/lemmas/autocomplete?term=a'
    assert last_response.body.include?('Augapfel')
    assert last_response.body.include?('Apfel')
  end
end
  