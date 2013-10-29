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

        def command_exited(result)
          if result.exit_code != 0 && !@options[:force]
            raise Errors::CommandFailed, :command => raw_command, :stderr => result.stderr
          end
          if @options[:stdout] == nil || @options[:stdout]
            @env[:ui].info "Command output:\n\n#{result.stdout}\n"
          end
        end

        def execute_guest(raw_command)
          @env[:ui].info 'Executing command "' + raw_command + '" on guest machine...'

          stdout = stderr = ""
          exit_code = @env[:machine].communicate.execute(raw_command) do |type, data|
            if type == :stdout
              stdout << data
            elsif type == :stderr
              stderr << data
            end
          end

          result = Vagrant::Util::Subprocess::Result.new(exit_code, stdout, stderr)
          command_exited(result)
        end

        def execute(raw_command)
          @env[:ui].info 'Executing command "' + raw_command + '"...'
          command     = Shellwords.shellsplit(raw_command)
          env_backup  = ENV.to_hash
          begin
            result = Vagrant::Util::Subprocess.execute(command[0], *command[1..-1])
          rescue Vagrant::Errors::CommandUnavailable, Vagrant::Errors::CommandUnavailableWindows
            @logger.debug("Command not found in the path.")
            @logger.debug("Current PATH: #{ENV["PATH"]}")
            new_path = Array(@options[:append_to_path]).join(File::PATH_SEPARATOR)
            @logger.debug("Temporary replacing the system PATH with #{new_path}.")
            unless new_path.empty?
              new_env = env_backup.dup
              new_env.delete("PATH")
              new_env["PATH"] = new_path
              ENV.replace(new_env)
              @options[:append_to_path] = nil
              retry
            end
            raise Errors::CommandUnavailable, :command => command[0]
          ensure
            ENV.replace(env_backup)
          end
          command_exited(result)
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
              @options = trigger[:options]

              if @options[:target] == "guest"
                method = "execute_guest"
              elsif !@options[:target] || @options[:target] == "host"
                method = "execute"
              else
                raise Errors::TargetUnavailable, :target => @options[:target]
              end

              if @options[:execute]
                send(method, @options[:execute])
              else
                @logger.debug("Trigger command not found.")
              end # if @options[:execute]
            end # triggers_to_fire.each do

          end #unless
        end # fire_triggers

      end
    end
  end
end
