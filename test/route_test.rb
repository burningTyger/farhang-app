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
    get '/css/layout.css'
    assert last_response.body.include?('#disqus_thread')
  end

  def test_js
    get '/js/application.js'
    assert last_response.body.include?('$(document).ready')
  end
  
  def test_get_search_ok
    l = Factory(:lemma, :lemma  => 'Apfel')
    get '/search/Apfel'
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
    
    get '/search/apfel'
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
    l.destroy
  end

  def test_search_ok
    l = Factory(:lemma, :lemma => 'Apfel')
    get '/search', :term => 'Apfel'
    follow_redirect!
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
    
    get '/search', :term => 'apfel'
    follow_redirect!
    assert last_response.body.include?('Apfel')
    refute last_response.body.include?('Augapfel')
    l.destroy
  end

  def test_show_lemma_id
    l = Factory(:lemma)
    get "/lemma/#{l.id}"
    assert last_response.body.include?('das_schweigende_lemma')
    l.destroy
  end
  
  def test_get_lemma
    l = Factory(:lemma)
    get "/lemma", :lemma => l.lemma
    assert last_response.body.include?('das_schweigende_lemma')
    l.destroy
  end

  def test_get_lemma_404
    l = Factory(:lemma)
    get "/lemma", :lemma => "alles_quatsch"
    assert last_response.status, 404
    l.destroy
  end
  
  def test_show_translation_id
    t = Factory(:translation)
    get "/translation/#{t.id}"
    assert last_response.body.include?('warum nicht?')
    t.destroy
  end
  
  def test_change_many_translation_lemma_put
    l = Factory(:lemma)
    t = Factory(:translation)
    put "/lemma/#{l.id}/translations", :translation_id => t.id
    assert last_response.body.include?('true')
    l.reload
    assert l.translation_ids.include?(t.id)
    l.destroy
    t.destroy
  end

  def test_change_many_translation_lemma_put_twice
    l = Factory(:lemma)
    t = Factory(:translation)
    put "/lemma/#{l.id}/translations", :translation_id => t.id
    put "/lemma/#{l.id}/translations", :translation_id => t.id
    l.reload
    assert l.translation_ids.include?(t.id)
    assert l.translation_ids == l.translation_ids.uniq
    l.destroy
    t.destroy
  end
  
  def test_change_many_translation_lemma_delete
    l = Factory(:lemma)
    t = Factory(:translation)
    put "/lemma/#{l.id}/translations", :translation_id => t.id
    delete "/lemma/#{l.id}/translations", :translation_id => t.id
    assert last_response.body.include?('true')
    l.reload
    refute l.translation_ids.include?(t.id)
    l.destroy
    t.destroy
  end
  
  def test_change_many_translation_lemma_404
    l = Factory(:lemma)
    t = Factory(:translation)
    put "/lemma/#{l.id}/translations", :translation_id => 123
    assert last_response.status, 404
    l.destroy
    t.destroy
  end
  
  def test_autocomplete
    l = Factory(:lemma, :lemma  => 'Apfel')
    l2 = Factory(:lemma, :lemma  => 'Augapfel')
    get '/lemmas/autocomplete', :term => 'a'
    assert last_response.body.include?('Augapfel')
    assert last_response.body.include?('Apfel')
    l.destroy
    l2.destroy
  end
  
  def test_new_lemma_wo_trans
    post '/lemma', :lemma_input => 'Traum',
                   :translationSource_0 => 'Traum',
                   :translationTarget_0 => 'dream'
    assert last_response.body.include?('dream')
    assert last_response.body.include?('Traum')
    Lemma.first(:lemma => 'Traum').destroy
    Translation.first(:source => 'Traum').destroy
  end

  def test_new_lemma_w_trans
    post '/lemma', :lemma_input => 'Traum',
                   :translationSource_0 => 'Traum',
                   :translationTarget_0 => 'dream',
                   :translationSource_1 => 'sommer',
                   :translationTarget_1 => 'winter'
    assert last_response.body.include?('dream')
    assert last_response.body.include?('Traum')
    assert last_response.body.include?('winter')
    Lemma.first(:lemma => 'Traum').destroy
    Translation.first(:source => 'Traum').destroy
    Translation.first(:source => 'sommer').destroy
  end

  def test_new_lemma_w_trans_fail
    post '/lemma', :lemma_input => 'Traum',
                   :translationSource_0 => 'Traum',
                   :translationTarget_0 => 'dream',
                   :translationTarget_1 => 'winter'
    assert last_response.body.include?('Traum')
    assert last_response.body.include?('dream')
    refute last_response.body.include?('winter')
    Lemma.first(:lemma => 'Traum').destroy
  end
end
  