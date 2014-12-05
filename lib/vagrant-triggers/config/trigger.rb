module VagrantPlugins
  module Triggers
    module Config
      class Trigger < Vagrant.plugin("2", :config)
        attr_reader :triggers

        def initialize
          @triggers = []
        end

        def after(actions, options = {}, &block)
          add_trigger(actions, :after, options, block)
        end

        def before(actions, options = {}, &block)
          add_trigger(actions, :before, options, block)
        end

        def instead_of(actions, options = {}, &block)
          add_trigger(actions, :instead_of, options, block)
        end
        alias_method :reject, :instead_of

        def merge(other)
          super.tap do |result|
            result.instance_variable_set(:@triggers, @triggers + other.triggers)
          end
        end

        def validate(machine)
          errors = []

          if @__invalid_methods && !@__invalid_methods.empty?
            errors << I18n.t("vagrant.config.common.bad_field", :fields => @__invalid_methods.to_a.sort.join(", "))
          end

          { "triggers" => errors }
        end

        private

        def add_trigger(actions, condition, options, proc)
          Array(actions).each do |action|
            @triggers << { :action => action, :condition => condition, :options => options, :proc => proc }
          end
        end
      end
    end
  end
end
