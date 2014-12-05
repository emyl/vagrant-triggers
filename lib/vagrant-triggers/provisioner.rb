module VagrantPlugins
  module Triggers
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config)
        @config  = config
        @dsl     = DSL.new(machine, @config.options)
      end

      def configure(root_config)
      end

      def provision
        @dsl.instance_eval &@config.trigger_body
      end

      def cleanup
      end
    end
  end
end
