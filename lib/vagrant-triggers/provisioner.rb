module VagrantPlugins
  module Triggers
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config)
        @config  = config
        begin
          @dsl = DSL.new(machine, @config.options)
        rescue Errors::NotMatchingMachine
          ENV["VAGRANT_NO_TRIGGERS"] = "1"
        end
      end

      def configure(root_config)
      end

      def provision
        unless ENV["VAGRANT_NO_TRIGGERS"]
          @dsl.instance_eval &@config.trigger_body
        end
      end

      def cleanup
      end
    end
  end
end
