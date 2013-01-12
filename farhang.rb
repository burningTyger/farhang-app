# encoding: UTF-8
#
# Farhang-app
#
# Author:: burningTyger (https://github.com/burningTyger)
# Home:: https://github.com/burningTyger/farhang-app
# Copyright:: Copyright (c) 2011 – 2012 burningTyger
# License:: MIT License
#
require 'sinatra'
require 'slim'
require 'sass'
require 'mongo_mapper'
require 'versionable'
require 'sinatra/reloader' if development?
require 'digest/sha1'
require 'bcrypt'
require "#{File.dirname(__FILE__)}/auth"
require "#{File.dirname(__FILE__)}/config" if production?
include Authentication

configure do
  set :slim, :pretty => true
  enable :sessions
  set :session_secret, SECRET ||= 'super secret'
  set :auth do |*roles|
    condition do
      roles? roles
    end
  end
  set :self_check do |*p|
    condition do
      @current_user.id == params[:id]
    end
  end
  if ENV['RACK_ENV'] == 'production'
    MongoMapper.database = APP_NAME
    MongoMapper.connection = Mongo::Connection.new(DB_HOST, DB_PORT)
    MongoMapper.database.authenticate(DB_USER, DB_PASS)
    MongoMapper.handle_passenger_forking
  elsif ENV['RACK_ENV'] == 'testing'
    MongoMapper.connection = Mongo::Connection.new('localhost')
    MongoMapper.database = "testing"
  else
    MongoMapper.connection = Mongo::Connection.new('localhost')
    MongoMapper.database = "development"
  end
end

FARHANG_VERSION = "0.9.9"

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
      roles << :root if User.count == 0
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
  enable_versioning :limit => 0
  key :lemma, String, :unique => true, :required => true
  key :edited_by, String
  key :valid, Boolean
  many :translations
  timestamps!

  def set_translations(params)
    params.values.each do |t|
      next if t["source"].nil? || t["target"].nil?
      next if t["source"].empty? || t["target"].empty?
      translations << Translation.new(:source => t["source"], :target => t["target"])
    end
  end
end

class Translation
  include MongoMapper::EmbeddedDocument
  key :source, String
  key :target, String
end

class Preferences
  include MongoMapper::Document
  key :analytics, String
  key :keywords, String
  key :description, String
end

not_found do
  'page not found'
end

error do
  'error'
end

helpers do
  def partial(template, locals = {})
    slim template, :layout => false, :locals => locals
  end

  def preferences
    Preferences.first || Preferences.new
  end

  def flash
    @flash = session.delete(:flash)
  end

  def roles? roles
    return false unless signed_in?
    @current_user.roles << :self if @current_user.id.to_param == params[:id]
    set = @current_user.roles & roles.to_set
    !set.empty?
  end
end

before do
  # just get rid of all these empty params
  # which makes checking them a lot easier
  # which also makes it impossible to empty a value... RETHINK!
  params.delete_if { |k, v| v.empty? }
end

# sass style sheet generation
get '/css/:file.css' do
  halt 404 unless File.exist?("views/#{params[:file]}.scss")
  time = File.stat("views/#{params[:file]}.scss").ctime
  last_modified(time)
  scss params[:file].intern
end

# offer a pingable route with low overhead
get '/ping' do
  halt 200
end

get '/' do
  slim :home, :locals => { :title => "Startseite" }
end

get '/search' do
  if params[:term]
    redirect "/search/#{params[:term]}"
  else
    redirect '/'
  end
end

get '/search/:term' do
  search_term = params[:term]
  search_term.gsub!(/[%20]/, ' ')
  lemmas = Lemma.all(:lemma => /^#{Regexp.escape(search_term)}/i)
  slim :search, :locals => { :lemmas => lemmas, :title => "Suche nach #{Regexp.escape(search_term)}" }
end

get '/lemma/autocomplete.json' do
  content_type :json
  lemmas = Lemma.where(:lemma => Regexp.new(/^#{params[:term]}/i)).limit(10)
  lemmas.map{ |l| l.lemma }.to_json(:only => :lemma)
end

get '/lemma/new', :auth => [:user] do
  slim :lemma_new, :locals => { :title => "Neuen Eintrag anlegen" }
end

post '/lemma', :auth => [:user] do
  redirect back if Lemma.find(:lemma => params[:lemma])
  l = Lemma.new(:lemma => params[:lemma])
  if params[:translations]
    l.set_translations(params[:translations])
  else
    redirect back
  end
  l.valid = roles?([:root, :admin])
  if l.save :updater_id => @current_user.id
    session[:flash] = ["Der Eintrag wurde erfolgreich angelegt", "alert-success"]
    redirect to("/lemma/#{l.id}/preview")
  else
    session[:flash] = ["Der Eintrag konnte nicht angelegt werden", "alert-error"]
    redirect back
  end
end

get '/lemma/validation', :auth => [:root, :admin] do
  lemmas = Lemma.all :valid => false
  slim :lemma_validation, :locals => { :lemmas => lemmas, :title => "Lemmas bestätigen" }
end

get '/lemma/:id' do
  halt 404 unless lemma = Lemma.find(params[:id])
  if authorized?
    slim :lemma_edit, :locals => { :lemmas => Array(lemma), :title => "#{lemma.lemma} bearbeiten" }
  else
    slim :partial_lemma, :locals => { :lemmas => Array(lemma), :title => lemma.lemma }
  end
end

get '/lemma/:id/preview' do
  halt 404 unless lemma = Lemma.find(params[:id])
  slim :partial_lemma, :locals => { :lemmas => Array(lemma), :title => lemma.lemma }
end

put '/lemma/:id', :auth => [:user] do
  halt 404 unless l = Lemma.find(params[:id])
  l.lemma = params[:lemma] if params[:lemma]
  if params[:translations]
    l.translations.clear
    l.set_translations(params[:translations])
  end
  l.valid = roles?([:root, :admin])
  if l.save :updater_id => @current_user.id
    session[:flash] = ["Änderungen erfolgreich gespeichert", "alert-success"]
    redirect "/lemma/#{l.id}/preview"
  else
    session[:flash] = ["Änderungen konnten nicht gespeichert werden", "alert-error"]
    redirect back
  end
end

patch '/lemma/:id/valid', :auth => [:admin, :root] do
  halt 404 unless l = Lemma.find(params[:id])
  if params[:valid] == 'true'
    l.valid = true
  else
    versions = l.versions.reverse
    version = versions.find { |v| v.data[:valid] }
    if version
      l.rollback(version.pos)
    else
      l.destroy
    end
  end
  l.save if l.valid
  redirect back
end

delete '/lemma/:id', :auth => [:admin, :root] do
  halt 404 unless lemma = Lemma.find(params[:id])
  if lemma.destroy
    session[:flash] = ["Eintrag erfolgreich gelöscht", "alert-success"]
    redirect to("/")
  else
    session[:flash] = ["Eintrag konnte nicht gelöscht werden", "alert-error"]
    redirect back
  end
end

## User routes
get '/users', :auth => [:root, :admin] do
  slim :users, :locals => { :users => User.all, :title => "Benutzer" }
end

get '/user/login' do
  slim :login, :locals => { :title => "Login" }
end

get '/user/new' do
  slim :user_new, :locals => { :title => "Neu anmelden" }
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

get '/user/:id', :auth => [:self, :root] do
  halt 404 unless u = User.find(params[:id])
  slim :user, :locals => { :user => u, :title => u.email }
end

put '/user/:id', :auth => [:self, :root] do
  halt 404 unless u = User.find(params[:id])
  if u.update_attributes! params
    session[:flash] = ["Änderungen erfolgreich gespeichert", "alert-success"]
    redirect to("/users")
  else
    halt 409, "Resource konnte nicht geändert werden"
  end
end

patch '/user/:id/roles', :auth =>  [:root] do
  halt 404 unless user = User.find(params[:id])
  if !params[:roles] || params[:roles].empty?
    break
  elsif user == User.first
    session[:flash] = ["Benutzerrechte des Besitzers können nicht geändert werden", "alert-error"]
  else
    roles = []
    roles << :user << params[:roles].to_sym
    user.roles.replace roles.to_set
    if user.save
      session[:flash] = ["Benutzerrechte erfolgreich geändert", "alert-success"]
    else
      session[:flash] = ["Fehler. Benutzerrechte konnten nicht geändert werden", "alert-error"]
    end
  end
  redirect to("/users")
end

delete '/user/:id', :auth => [:self, :root] do
  halt 404 unless u = User.find(params[:id])
  if u.destroy
    session[:flash] = ["Benutzer erfolgreich gelöscht", "alert-success"]
    if roles? [:root]
      redirect to("/users")
    else
      redirect to("/user/logout")
    end
  else
    halt 400, "Eintrag konnte nicht gelöscht werden"
  end
end

post '/user/login' do
  authenticate_with_login_form params[:email], params[:password]
  redirect to('/')
end

get '/app/preferences', :auth => [:root] do
  slim :preferences, :locals => { :title => "Einstellungen" }
end

put '/app/preferences', :auth => [:root] do
  if preferences.update_attributes! params
    session[:flash] = ["Änderungen erfolgreich gespeichert", "alert-success"]
    redirect to("/app/preferences")
  else
    halt 409, "Einstellungen konnte nicht geändert werden"
  end
end

get '/app/sitemap', :auth => [:root] do
  attachment "sitemap.txt"
  lemmas = Lemma.all
  lemmas.map do |l|
    "#{request.url.gsub('app/sitemap','')}#{l.id.to_s}\n"
  end
end

