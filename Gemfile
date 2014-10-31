source "http://rubygems.org"
gem 'sinatra'
gem 'slim'
gem 'sass'
gem 'mongo_mapper'
gem 'bson_ext', :platforms => :ruby
gem 'bson', :platforms => :jruby
gem 'bcrypt'
gem 'mm-versionable', :require => 'versionable'
gem 'mm-sluggable'
gem 'unicode', :platforms => :ruby
gem 'babosa'

group :production do
  gem 'newrelic_rpm'
  gem 'puma'
end

group :development, :test do
  gem 'minitest', '~>5'
  gem 'sinatra-contrib'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'rake'
end

