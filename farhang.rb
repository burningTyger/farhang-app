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
require 'coffee-script'
require 'sinatra/reloader' if development?

configure do
  set :server, %w[puma thin]
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

FARHANG_VERSION = "0.1"

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
    redirect '/search'
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
  haml :search, :locals => { :lemmas => lemmas }
end

get '/lemmas/autocomplete' do
  lemmas = Lemma.where(:lemma => Regexp.new(/^#{params[:term]}/i)).limit(10)
  lemmas.map{ |l| l.lemma }.to_json(:only => :lemma)
end

get '/lemma' do
  content_type :json
  l = Lemma.first(params)
  halt 404 unless l
  l.to_json
end

get '/lemma/:id' do
  halt 404 unless params[:id]
  lemma = Lemma.find(params[:id])
  haml :lemma, :locals => { :lemmas => Array(lemma) }
end

post '/lemma' do
  halt 400 unless params[:lemma_input]
  l = Lemma.find_or_create_by_lemma(params[:lemma_input])
  
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
  haml :lemma, :locals => { :lemmas => Array(l) }, :layout => false
end

=begin
put 'lemma/:id' do
  halt 404 unless params[:id]
  
end

=end
get '/translation/:id' do
  halt 404 unless params[:id]
  translation = Translation.find(params[:id])
  haml :translation, :locals => { :translation => translation }
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
  haml :translations, :locals => { :translation => translation }
end



get '/' do
  haml :home
end
