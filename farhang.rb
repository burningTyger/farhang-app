require 'sinatra'
require 'rack/cache'
require 'sass'
require 'sequel'
require 'sqlite3'
require 'babosa'
require 'envyable'
require 'newrelic_rpm' if production?

newrelic_ignore '/ping' if production?

Envyable.load('config/env.yml')
DB = Sequel.connect("sqlite://#{ENV["F_DB"]}",
                    :after_connect=>proc{|conn| conn.enable_load_extension(true);
                                                conn.load_extension(File.expand_path File.dirname(__FILE__)+"/libicu")}
                   )
at_exit {DB.disconnect; puts "Datenbank »#{ENV['F_DB']}« geschlossen"}

class Lemma < Sequel::Model
  one_to_many :translations

  def before_create
    super
    self.lemma.strip!
    set_slug!
  end

  def before_update
    super
    self.lemma.strip!
    set_slug! if modified?(:lemma)
  end

  def before_destroy
    super
    self.remove_all_translations
  end

  def set_slug!
    self.slug = lemma.to_slug.clean.normalize(:transliterate => :german).to_s
    if l = Lemma.find(:slug => self.slug)
      nr = (l.lemma.split("").last.to_i)+1
      self.slug = self.slug+"_"+nr.to_s
    end
  end
end

class Translation < Sequel::Model
  def before_create
    super
    self.source.strip!
    self.target.strip!
  end
end

module Farhang
  class Farhang < Sinatra::Application
    configure do
      use Rack::Cache,
        metastore:    'file:./tmp/rack/meta',
        entitystore:  'file:./tmp/rack/body',
        verbose:      false
      enable :sessions
      set :session_secret, ENV['F_SESSION_SECRET']
    end

    helpers do
      def partial(template, locals = {})
        slim template, :layout => false, :locals => locals
      end

      def devowelize(str)
        str.delete("\u064B-\u0655")
      end
    end

    not_found do
      redirect to('/')
    end

    error do
      'error'
    end

    before do
      params.delete_if { |k, v| v && v.empty? }
    end

    # sass style sheet generation
    get '/css/:file.css' do
      halt 404 unless File.exist?("views/#{params[:file]}.scss")
      time = File.stat("views/#{params[:file]}.scss").ctime
      last_modified(time)
      scss params[:file].intern
    end

    get '/' do
      slim :home, :locals => { :count => Lemma.count, :count_translation => Translation.count, :title => "Startseite" }
    end
  end

  class FarhangClient < Farhang
    get '/search/autocomplete.json' do
      content_type :json
      term = params[:term].strip.force_encoding("UTF-8")
      lemmas = Lemma.where(Sequel.ilike(:lemma, "#{devowelize(term)}%")).limit(10).order(:lemma)
      lemmas = lemmas.map{ |l| { :value => l.lemma,
                                 :link => l.slug}}
      lemmas.to_json
    end

    get '/search' do
      redirect '/' unless params[:term]
      term = params[:term].strip.force_encoding("UTF-8")
      lemmas = Lemma.where(Sequel.ilike(:lemma, "#{devowelize(term)}%")).eager(:translations).order(Sequel.lit('LOWER(lemma) ASC')).all
      slim :lemma, :locals => { :lemmas => lemmas, :title => "Suche nach #{Regexp.escape(term)}" }
    end

    get '/:slug' do
      slug = params[:slug].force_encoding("UTF-8")
      if lemma = Lemma.find(:slug => slug)
        slim :lemma, :locals => { :lemmas => Array(lemma),
                                  :title => lemma.lemma}
      else
        redirect "/search?#{slug}"
      end
    end

    get('/app/ping'){}

    get '/app/sitemap' do
      attachment "sitemap.txt"
      lemmas = Lemma.select(:slug).all
      root = request.url.gsub('app/sitemap','')
      lemmas.map {|l| "#{root}#{l.slug}\n"} << root
    end

    get '/app/download/db' do
      zip = `gzip --keep --force farhang.db`
      attachment "farhang.db.gz"
    end
  end

  class FarhangEditor < Farhang
    configure do
      use Rack::Auth::Basic, "Passwortgeschuetzter Bereich" do |username, password|
        username == ENV["F_USER"] && password == ENV["F_PASS"]
      end
    end

    get '/new' do
      slim :lemma_new, :locals => { :title => "Neuen Eintrag anlegen" }
    end

    get '/search' do
      redirect to('/new')
    end

    get '/:slug' do
      slug = params[:slug].force_encoding("UTF-8")
      lemma = Lemma.find(:slug => slug)
      slim :lemma_edit, :locals => { :lemma => lemma, :title => "#{lemma.lemma} bearbeiten"}
    end

    post '/new' do
      lemma = params[:lemma].force_encoding("UTF-8")
      redirect back if Lemma.find(:lemma => lemma)
      l = Lemma.create(:lemma => lemma)
      if params[:translations]
        params[:translations].each do |t|
          next if t.values.any?{|v| v.nil? || v.empty?}
          l.add_translation Translation.create t
        end
      else
        redirect back
      end
      redirect to("/#{l.slug}")
    end

    put '/:id' do
      halt 404 unless l = Lemma[params[:id]]
      l.update(:lemma => params[:lemma]) if params[:lemma]
      if params[:translations]
        l.remove_all_translations
        params[:translations].each do |t|
          next if t.values.any?{|v| v.nil? || v.empty?}
          l.add_translation Translation.create t
        end
      end
      redirect to("/#{l.slug}")
    end

    delete '/:id' do
      halt 404 unless lemma = Lemma[params[:id]]
      if lemma.destroy
        redirect to("/")
      else
        redirect back
      end
    end
  end
end
