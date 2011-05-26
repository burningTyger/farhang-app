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
    get '/css/home.css'
    assert last_response.body.include?('helvetica')
  end

  def test_search_ok
    get '/?search=Apfel'
    assert last_response.body.include?('<b>Apfel</b>')
    assert last_response.body.include?('<b>Augapfel</b>')
    
    get '/?search=apfel'
    assert last_response.body.include?('<b>Apfel</b>')
    assert last_response.body.include?('<b>Augapfel</b>')
    
  end

end
  