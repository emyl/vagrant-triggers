require "log4r"
require "shellwords"
require "vagrant/util/subprocess"

module VagrantPlugins
  module Triggers
    module Action
      class Trigger
        def initialize(app, env, condition)
          @app       = app
          @condition = condition
          @env       = env
          @logger    = Log4r::Logger.new("vagrant::plugins::triggers::trigger")
        end

        def call(env)
          fire_triggers
          
          # Carry on
          @app.call(env)
        end

        def fire_triggers
          # Triggers don't fire on environment load and unload.
          return if [:environment_load, :environment_unload].include?(@env[:action_name])
          current_action   = @env[:machine_action]
          # Also don't fire if machine action is not defined.
          return unless current_action
          @logger.debug("Looking for triggers #{@condition} action #{current_action}.")
          triggers_to_fire = @env[:machine].config.trigger.triggers.find_all { |t| t[:action] == current_action && t[:condition] == @condition }
          unless triggers_to_fire.empty?
            @env[:ui].info "Running triggers #{@condition} action..."
            triggers_to_fire.each do |trigger|
              options = trigger[:options]
              if options[:execute]
                raw_command = options[:execute]
                @env[:ui].info 'Executing command "' + raw_command + '"...'
                command     = Shellwords.shellsplit(raw_command)
                result      = Vagrant::Util::Subprocess.execute(command[0], *command[1..-1])
                if result.exit_code != 0 && !options[:force]
                  raise Errors::CommandFailed, :command => raw_command, :stderr => result.stderr
                end
                if options[:stdout]
                  @env[:ui].info "Command output:\n\n#{result.stdout}\n"
                end
              else
                @logger.debug("Trigger command not found.")
              end
            end
          end
        end
      end
    end
  end
end