# encoding: UTF-8
#
# Farhang-app
#
# Author:: burningTyger (https://github.com/burningTyger)
# Home:: https://github.com/burningTyger/farhang-app
# Copyright:: Copyright (c) 2011 burningTyger
# License:: MIT License
#
require 'sinatra'
require 'slim'
require 'sass'
require 'mongo_mapper'
#require 'coffee-script'
require 'sinatra/reloader' if development?
require 'digest/sha1'
require 'bcrypt'
require_relative 'auth'

include Authentication

configure do
  set :slim, :pretty => true
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || 'super secret'
  set :auth do |*roles|
    condition do
      roles? roles
    end
  end

  if ENV['MONGOLAB_URL']
    MongoMapper.database = ENV['MONGOLAB_DATABASE']
    MongoMapper.connection = Mongo::Connection.new(ENV['MONGOLAB_URL'], ENV['MONGOLAB_PORT'])
    MongoMapper.database.authenticate(ENV['MONGOLAB_USER'], ENV['MONGOLAB_PASS'])
  elsif ENV['RACK_ENV'] == 'testing'
    MongoMapper.connection = Mongo::Connection.new('localhost')
    MongoMapper.database = "testing"
  else
    MongoMapper.connection = Mongo::Connection.new('localhost')
    MongoMapper.database = "development"
  end
end

FARHANG_VERSION = "2.0.0"

class User
  include MongoMapper::Document
  attr_accessible :email, :password

  key :email, String, :required => true, :unique => true
  key :crypted_password, String
  key :reset_password_code, String
  key :reset_password_code_until, Time
  key :roles, Set
  timestamps!

  validate :role_validation

  def role_validation
    if roles.count == 0
      roles << :user
    end
  end

  RegEmailName   = '[\w\.%\+\-]+'
  RegDomainHead  = '(?:[A-Z0-9\-]+\.)+'
  RegDomainTLD   = '(?:[A-Z]{2}|com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum)'
  RegEmailOk     = /\A#{RegEmailName}@#{RegDomainHead}#{RegDomainTLD}\z/i

  def self.authenticate(email, secret)
    u = User.first(:conditions => {:email => email.downcase})
    u && u.authenticated?(secret) ? u : nil
  end

  validates_length_of :email, :within => 6..100, :allow_blank => true
  validates_format_of :email, :with => RegEmailOk, :allow_blank => true

  PasswordRequired = Proc.new { |u| u.password_required? }
  validates_presence_of :password, :if => PasswordRequired
  validates_confirmation_of :password, :if => PasswordRequired, :allow_nil => true
  validates_length_of :password, :minimum => 6, :if => PasswordRequired, :allow_nil => true

  def authenticated?(secret)
    password == secret ? true : false
  end

  def password
    if crypted_password.present?
      @password ||= BCrypt::Password.new(crypted_password)
    else
      nil
    end
  end

  def password=(value)
    if value.present?
      @password = value
      self.crypted_password = BCrypt::Password.create(value)
    end
  end

  def email=(new_email)
    new_email.downcase! unless new_email.nil?
    write_attribute(:email, new_email)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def set_password_code!
    seed = "#{email}#{Time.now.to_s.split(//).sort_by {rand}.join}"
    self.reset_password_code_until = 1.day.from_now
    self.reset_password_code = Digest::SHA1.hexdigest(seed)
    save!
  end
end

class Lemma
  include MongoMapper::Document

  key :lemma, String, :unique => true, :required => true
  key :translation_ids, Array
  many :translations, :in => :translation_ids
  timestamps!
end

class Translation
  include MongoMapper::Document

  key :source, String
  key :target, String
  key :lemma_ids, Array
  many :lemmas, :in => :lemma_ids
  timestamps!
end

not_found do
  'page not found'
end

error do
  'error'
end

helpers do
  def partial (template, locals = {})
    slim template, :layout => false, :locals => locals
  end

  def flash
    @flash = session.delete(:flash)
  end

  # this method removes kasra, fatha and damma from lemma
  # by doing a unicode range check on the string
  def devowelize(str)
    str.delete("\u064B-\u0655")
  end

  def set_params_page
    params[:page] = params.fetch("page"){1}.to_i
    params[:per_page] = params.fetch("per_page"){20}.to_i
  end

  def set_pagination_buttons(data, options = {})
    return if data.nil? || data.empty?

    if data.next_page
      params = {
        :page     => data.next_page,
        :per_page => data.per_page
        }.merge(options)
      @next_page = "?#{Rack::Utils.build_query params}"
    end

    if data.previous_page
      params = {
        :page     => data.previous_page,
        :per_page => data.per_page
        }.merge(options)
      @prev_page = "?#{Rack::Utils.build_query params}"
    end
  end

  def roles?(roles)
    authenticate unless signed_in?
    @current_user.roles & roles.to_set
  end
end

before do
  # just get rid of all these empty params
  # which makes checking them a lot easier
  params.delete_if { |k, v| v.empty? }
end

# sass style sheet generation
get '/css/:file.css' do
  halt 404 unless File.exist?("views/#{params[:file]}.scss")
  time = File.stat("views/#{params[:file]}.scss").ctime
  last_modified(time)
  scss params[:file].intern
end

# coffeescript js generation
get '/js/:file.js' do
  halt 404 unless File.exist?("views/#{params[:file]}.coffee")
  time = File.stat("views/#{params[:file]}.coffee").ctime
  last_modified(time)
  coffee params[:file].intern
end

get '/search' do
  if params[:term]
    redirect "/search/#{params[:term]}"
  else
    redirect '/'
  end
end

get '/search/:term' do
  if params[:term]
    search_term = devowelize(params[:term])
    search_term.gsub!(/[%20]/, ' ')
    #search_term.gsub!(/\*/, '\*')
    # replace *: in conversion with Link to lemma
    lemmas = Lemma.all(:lemma => Regexp.new(/^#{search_term}/i))
  end
  slim :search, :locals => { :lemmas => lemmas }
end

get '/lemmas/autocomplete.json' do
  content_type :json
  lemmas = Lemma.where(:lemma => Regexp.new(/^#{params[:term]}/i)).limit(10)
  puts lemmas.map{ |l| l.lemma }.to_json(:only => :lemma)
  lemmas.map{ |l| l.lemma }.to_json(:only => :lemma)
end

get '/lemma/:id' do
  halt 404 unless params[:id]
  lemma = Lemma.find(params[:id])
  slim :lemma, :locals => { :lemmas => Array(lemma) }
end

post '/lemma/new' do
  halt 400 unless params[:lemma]
  l = Lemma.find_or_create_by_lemma(params[:lemma])

  i = 0
  while true;
    break unless params[:"translationSource_#{i}"] && params[:"translationTarget_#{i}"]
    t = Translation.find_or_create_by_source_and_target(params[:"translationSource_#{i}"], params[:"translationTarget_#{i}"])
    t.lemmas << l
    l.translations << t
    halt 400 unless t.save
    i += 1
  end

  halt 400 unless l.save
  slim :lemma, :locals => { :lemmas => Array(l) }, :layout => false
end

get '/translation/:id' do
  halt 404 unless params[:id]
  translation = Translation.find(params[:id])
  slim :translation, :locals => { :translation => translation }
end

put '/lemma/:id/translations' do
  l = Lemma.find(params[:id])
  t = Translation.find(params[:translation_id])
  halt 404 unless l && t

  l.translations << t
  t.lemmas << l
  
  content_type :json
  (l.save && t.save).to_json
end

delete '/lemma/:id/translations' do
  l = Lemma.find(params[:id])
  t = Translation.find(params[:translation_id])
  halt 404 unless l && t

  l.translation_ids.delete(t.id)
  t.lemma_ids.delete(l.id)

  content_type :json
  (l.save && t.save).to_json
end

get '/translations' do
  set_params_page
  translation = Translation
  translation = translation.sort(:source.desc)
  translation = translation.paginate(:page => params[:page], :per_page => params[:per_page])

  set_pagination_buttons(translation)
  slim :translations, :locals => { :translation => translation }
end

get '/' do
  if signed_in?
    slim :dashboard
  else
    slim :home
  end
end

## User routes
get '/users', :auth => [:root] do
  slim :users, :locals => { :users => User.all }
end

get '/user/new' do
  slim :user_new
end

get '/user/logout' do
  sign_out_keeping_session!
  redirect to('/')
end

post '/user' do
  user = User.new params
  halt 400 unless user.save
  session[:flash] = ["Benutzer erfolgreich angelegt", "alert-success"]
  redirect to('/')
end

get '/user/:id', :auth => [:user] do
  halt 404 unless u = User.find(params[:id])
  slim :user, :locals => { :user => u }
end

put '/user/:id', :auth => [:user] do
  halt 404 unless u = User.find(params[:id])
  if u.update_attributes! params
    session[:flash] = ["Änderungen erfolgreich gespeichert", "alert-success"]
    redirect to("/users")
  else
    halt 409, "Resource konnte nicht geändert werden"
  end
end

delete '/user/:id', :auth => [:user] do
  halt 404 unless u = User.find(params[:id])
  if u.destroy
    session[:flash] = ["Benutzer erfolgreich gelöscht", "alert-success"]
    redirect to("/users")
  else
    halt 400, "Eintrag konnte nicht gelöscht werden"
  end
end

post '/user/login' do
  authenticate_with_login_form params[:email], params[:password]
  redirect to('/')
end

