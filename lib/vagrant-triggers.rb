require "pathname"
require "vagrant-triggers/plugin"

module VagrantPlugins
  module Triggers
    lib_path = Pathname.new(File.expand_path("../vagrant-triggers", __FILE__))
    autoload :Action,   lib_path.join("action")
    autoload :DSL,      lib_path.join("dsl")
    autoload :Config,   lib_path.join("config")
    autoload :Errors,   lib_path.join("errors")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
