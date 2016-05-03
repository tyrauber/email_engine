require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require 'mock_redis'
require 'combustion'

Combustion.path = "test/internal"
Combustion.initialize! :all

EmailEngine.configure do |config|
  config.redis = MockRedis.new
end

Minitest::Test = Minitest::Unit::TestCase unless defined?(Minitest::Test)
ActionMailer::Base.delivery_method = :test
