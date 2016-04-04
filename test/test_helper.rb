ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/autorun'
require 'mongoid'
require 'mongoid-minitest'
require 'minitest/mock'

Dir[Rails.root.join('test/support/**/*.rb')].each { |f| require f }
DatabaseCleaner[:mongoid].strategy = :truncation

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
end

class MiniTest::Spec
  include Mongoid::Matchers
  include FactoryGirl::Syntax::Methods

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end
