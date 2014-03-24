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

        private

        def build_environment
          @logger.debug("Original environment: #{ENV.inspect}")

          # Remove GEM_ environment variables
          ["GEM_HOME", "GEM_PATH", "GEMRC"].each { |gem_var| ENV.delete(gem_var) }

          # Create the new PATH removing Vagrant bin directory
          # and appending directories specified through the
          # :append_to_path option
          new_path  = ENV["VAGRANT_INSTALLER_ENV"] ? ENV["PATH"].gsub(/#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}.*?#{File::PATH_SEPARATOR}/, "") : ENV["PATH"]
          new_path += Array(@options[:append_to_path]).map { |dir| "#{File::PATH_SEPARATOR}#{dir}" }.join
          ENV["PATH"] = new_path
          @logger.debug("PATH modifed: #{ENV["PATH"]}")

          # Add the VAGRANT_NO_TRIGGERS variable to avoid loops
          ENV["VAGRANT_NO_TRIGGERS"] = "1"
        end

        def execute(raw_command)
          @env[:ui].info 'Executing command "' + raw_command + '"...'
          command     = Shellwords.shellsplit(raw_command)
          env_backup  = ENV.to_hash
          begin
            build_environment
            result = Vagrant::Util::Subprocess.execute(command[0], *command[1..-1])
          rescue Vagrant::Errors::CommandUnavailable, Vagrant::Errors::CommandUnavailableWindows
            raise Errors::CommandUnavailable, :command => command[0]
          ensure
            ENV.replace(env_backup)
          end
          if result.exit_code != 0 && !@options[:force]
            raise Errors::CommandFailed, :command => raw_command, :stderr => result.stderr
          end
          if @options[:stdout]
            @env[:ui].info "Command output:\n\n#{result.stdout}\n"
          end
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
              if @options[:execute]
                execute(@options[:execute])
              elsif @options[:info]
                @env[:ui].info @options[:info]
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
