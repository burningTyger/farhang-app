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
require 'haml'
require 'sass'
require 'mongo_mapper'
require 'sinatra/reloader' if development?

configure do
  if ENV['MONGOLAB_URL']
    MongoMapper.database = ENV['MONGOLAB_DATABASE']
    MongoMapper.connection = Mongo::Connection.new(ENV['MONGOLAB_URL'], 27107)
    MongoMapper.database.authenticate(ENV['MONGOLAB_USER'], ENV['MONGOLAB_PASS'])
  else
    MongoMapper.connection = Mongo::Connection.new('localhost')
    MongoMapper.database = "testing"
  end
end

FARHANG_VERSION = "0.1"

class Lemma
  include MongoMapper::Document
  key :lemma, String
  key :translation_ids, Array
  many :translations, :in => :translation_ids
  timestamps!
end

class Translation
  include MongoMapper::Document
  key :source, String
  key :target, String
  timestamps!
end

not_found do
  'page not found'
end

error do
  'error'
end

#sass style sheet generation
get '/css/:file.css' do
  halt 404 unless File.exist?("views/#{params[:file]}.scss")
  time = File.stat("views/#{params[:file]}.scss").ctime
  last_modified(time)
  scss params[:file].intern
end

post '/search' do
  unless params[:term].nil? or params[:term].empty?
    redirect "/search/#{params[:term]}"
  else
    redirect '/search'
  end
end

get '/search/:term' do
  unless params[:term].nil? or params[:term].empty?
    lemmas = Lemma.all(:lemma => Regexp.new(/^#{params[:term]}/i))
  end
  haml :search, :locals => { :lemmas => lemmas }
end

get '/lemmas/:id' do
  unless params[:id].nil? or params[:id].empty?
    lemma = Lemma.find(params[:id])
  end
  haml :lemma, :locals => { :lemmas => lemma }
end

get '/translations/:id' do
  unless params[:id].nil? or params[:id].empty?
    translation = Translation.find(params[:id])
  end
  haml :translation, :locals => { :translation => translation }
end

get '/' do
  haml :home
end
