module VagrantPlugins
  module Triggers
    class Config < Vagrant.plugin("2", :config)
      attr_reader :triggers
      
      def initialize
        @triggers = []
      end

      def after(action, options = {})
        @triggers << { :action => action, :condition => :after, :options => options }
      end

      def before(action, options = {})
        @triggers << { :action => action, :condition => :before, :options => options }
      end      

      def validate(machine)
        errors = []

        if @__invalid_methods && !@__invalid_methods.empty?
          errors << I18n.t("vagrant.config.common.bad_field", :fields => @__invalid_methods.to_a.sort.join(", "))
        end

        { "triggers" => errors }
      end
    end
  end
end