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
          return if [:environment_load, :environment_plugins_loaded, :environment_unload].include?(@env[:action_name])

          # Also don't fire if machine action is not defined.
          return unless @env[:machine_action]

          @logger.debug("Looking for triggers with:")
          trigger_env.each { |k, v| @logger.debug("-- #{k}: #{v}")}

          # Loop through all defined triggers checking for matches.
          triggers_to_fire = [].tap do |triggers|
            @env[:machine].config.trigger.triggers.each do |trigger|
              next if trigger[:action]    != trigger_env[:action]
              next if trigger[:condition] != trigger_env[:condition]

              triggers << trigger
            end
          end

          unless triggers_to_fire.empty?
            @env[:ui].info I18n.t("vagrant_triggers.action.trigger.running_triggers", trigger_env).gsub('_', ' ')
            @exit = true if trigger_env[:condition] == :instead_of
          end

          triggers_to_fire.each do |trigger|
            if trigger[:proc]
              dsl = DSL.new(@env[:ui], trigger[:options])
              dsl.instance_eval &trigger[:proc]
            else
              @logger.debug("Trigger command not found.")
            end
          end
        end

        def trigger_env
          {
            :action    => @env[:machine_action],
            :condition => @condition
          }
        end
      end
    end
  end
end
