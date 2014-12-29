require "simplecov"
SimpleCov.start

require "vagrant"
require_relative "../lib/vagrant-triggers"

VagrantPlugins::Triggers::Plugin.init_i18n

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end
