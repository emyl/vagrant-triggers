module VagrantPlugins
  module Triggers
    module Config
      class Provisioner < Vagrant.plugin("2", :config)
        attr_reader :options
        attr_reader :trigger_body

        def initialize
          @options = {
            :good_exit => [0],
            :stderr    => true,
            :stdout    => true
          }
        end

        def fire(&block)
          @trigger_body = block
        end

        def set_options(options)
          @options.merge!(options)
        end
      end
    end
  end
end
