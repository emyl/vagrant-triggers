module VagrantPlugins
  module Triggers
    class Config < Vagrant.plugin("2", :config)
      attr_reader :triggers
      
      def initialize
        @triggers = []
      end

      def after(actions, options = {})
        add_trigger(actions, :after, options)
      end

      def before(actions, options = {})
        add_trigger(actions, :before, options)
      end      

      def validate(machine)
        errors = []

        if @__invalid_methods && !@__invalid_methods.empty?
          errors << I18n.t("vagrant.config.common.bad_field", :fields => @__invalid_methods.to_a.sort.join(", "))
        end

        { "triggers" => errors }
      end

      private

      def add_trigger(actions, condition, options)
        Array(actions).each do |action|
          @triggers << { :action => action, :condition => condition, :options => options }
        end
      end
    end
  end
end