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
gem 'babosa', '~> 0.3.11'

group :production do
  gem 'newrelic_rpm'
  gem 'skylight', '~> 0.6.0.beta.1'
  gem 'puma'
end

group :development, :test do
  gem 'minitest', '~> 5'
  gem 'sinatra-contrib'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'rake'
end

