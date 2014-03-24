require "simplecov"
SimpleCov.start

require "vagrant"
require_relative "../lib/vagrant-triggers"

VagrantPlugins::Triggers::Plugin.init_i18n
