# This is an example config file. Copy to config.rb and change the values as
# needed. Testing and development should work without this file.
#
# uncomment this line if you have a newrelic account
# require 'newrelic_rpm' if production

# Use Openshift env vars for db connectivity.
# Use your own credentials or other env vars like those on Heroku.
#
# Openshift env vars
APP_NAME     = ENV['OPENSHIFT_APP_NAME']
DB_HOST      = ENV['OPENSHIFT_MONGODB_DB_HOST']
DB_PORT      = ENV['OPENSHIFT_MONGODB_DB_PORT']
DB_USER      = ENV['OPENSHIFT_MONGODB_DB_USERNAME']
DB_PASS      = ENV['OPENSHIFT_MONGODB_DB_PASSWORD']
SECRET       = ENV['OPENSHIFT_CONTAINER_UUID']
