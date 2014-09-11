require "log4r"
require "shellwords"
require "vagrant/util/subprocess"

module VagrantPlugins
  module Triggers
    class DSL
      def initialize(ui, machine, options = {})
        @logger  = Log4r::Logger.new("vagrant::plugins::triggers::dsl")
        @machine = machine
        @options = options
        @ui      = ui
      end

      def error(message, *opts)
        raise Errors::DSLError, @ui.error(message, *opts)
      end

      def run(raw_command, options = {})
        info I18n.t("vagrant_triggers.action.trigger.executing_command", :command => raw_command)
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
        process_result(raw_command, result)
      end
      alias_method :execute, :run

      def run_remote(raw_command, options = {})
        stderr = ""
        stdout = ""
        exit_code = @machine.communicate.sudo(raw_command, :elevated => true, :good_exit => (0..255).to_a) do |type, data|
          if type == :stderr
            stderr += data
          elsif type == :stdout
            stdout += data
          end
        end
        process_result(raw_command, Vagrant::Util::Subprocess::Result.new(exit_code, stdout, stderr))
      end
      alias_method :execute_remote, :run_remote

      def method_missing(method, *args, &block)
        # If the @ui object responds to the given method, call it
        if @ui.respond_to?(method)
          @ui.send(method, *args, *block)
        else
          super(method, *args, &block)
        end
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
        @logger.debug("PATH modified: #{ENV["PATH"]}")

        # Remove bundler settings from RUBYOPT
        ENV["RUBYOPT"] = (ENV["RUBYOPT"] || "").gsub(/-rbundler\/setup\s*/, "")
        @logger.debug("RUBYOPT modified: #{ENV["RUBYOPT"]}")

        # Add the VAGRANT_NO_TRIGGERS variable to avoid loops
        ENV["VAGRANT_NO_TRIGGERS"] = "1"
      end

      def process_result(command, result)
        if result.exit_code != 0 && !@options[:force]
          raise Errors::CommandFailed, :command => command, :stderr => result.stderr
        end
        if @options[:stdout]
          info I18n.t("vagrant_triggers.action.trigger.command_output", :output => result.stdout)
        end
        result.stdout
      end
    end
  end
end
