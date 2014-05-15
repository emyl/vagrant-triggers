require "log4r"

module VagrantPlugins
  module Triggers
    module Action
      class Trigger
        def initialize(app, env, condition)
          @app       = app
          @condition = condition
          @env       = env
          @exit      = false
          @logger    = Log4r::Logger.new("vagrant::plugins::triggers::trigger")
        end

        def call(env)
          fire_triggers

          @app.call(env) unless @exit
        end

        private

        def fire_triggers
          # Triggers don't fire on environment load and unload.
          return if [:environment_load, :environment_unload].include?(@env[:action_name])
          current_action   = @env[:machine_action]
          # Also don't fire if machine action is not defined.
          return unless current_action
          @logger.debug("Looking for triggers #{@condition} action #{current_action}.")
          triggers_to_fire = @env[:machine].config.trigger.triggers.find_all { |t| t[:action] == current_action && t[:condition] == @condition }
          unless triggers_to_fire.empty?
            @env[:ui].info I18n.t("vagrant_triggers.action.trigger.running_triggers", :condition => @condition)
            triggers_to_fire.each do |trigger|
              if trigger[:proc]
                dsl = DSL.new(@env[:ui], trigger[:options])
                dsl.instance_eval &trigger[:proc]
              else
                  @logger.debug("Trigger command not found.")
              end
            end
            @exit = true if @condition == :instead_of
          end
        end
      end
    end
  end
end
