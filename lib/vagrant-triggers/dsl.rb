require "bundler"
require "log4r"
require "vagrant/util/subprocess"

module VagrantPlugins
  module Triggers
    class DSL
      def initialize(machine, options = {})
        if options[:vm]
          match = false
          Array(options[:vm]).each do |pattern|
            match = true if machine.name.match(Regexp.new(pattern))
          end
          raise Errors::NotMatchingMachine unless match
        end

        @buffer  = Hash.new("")
        @logger  = Log4r::Logger.new("vagrant::plugins::triggers::dsl")
        @machine = machine
        @options = options
        @ui      = machine.ui

        @command_output = lambda do |channel, data, options|
          ui_method = (channel == :stdout) ? :info : :error
          @buffer[channel] += data
          @ui.send(ui_method, data) if options[channel]
        end
      end

      def error(message, *opts)
        raise Errors::DSLError, @ui.error(message, *opts)
      end

      def run(raw_command, options = {})
        command = shellsplit(raw_command)
        options.merge!(@options) { |key, old, new| old }
        info I18n.t("vagrant_triggers.action.trigger.executing_command", :command => command.join(" "))
        env_backup = ENV.to_hash
        begin
          result = nil
          Bundler.with_clean_env do
            build_environment
            @buffer.clear
            Dir.chdir(@machine.env.root_path) do
              result = Vagrant::Util::Subprocess.execute(command[0], *command[1..-1], :notify => [:stdout, :stderr]) do |channel, data|
                @command_output.call(channel, data, options)
              end
            end
          end
          info I18n.t("vagrant_triggers.action.trigger.command_finished")
        rescue Vagrant::Errors::CommandUnavailable, Vagrant::Errors::CommandUnavailableWindows
          raise Errors::CommandUnavailable, :command => command[0]
        ensure
          ENV.replace(env_backup)
        end
        process_result(raw_command, result, options)
      end
      alias_method :execute, :run

      def run_remote(raw_command, options = {})
        options.merge!(@options) { |key, old, new| old }
        info I18n.t("vagrant_triggers.action.trigger.executing_remote_command", :command => raw_command)
        @buffer.clear
        exit_code = @machine.communicate.sudo(raw_command, :elevated => true, :good_exit => (0..255).to_a) do |channel, data|
          @command_output.call(channel, data, options)
        end
        info I18n.t("vagrant_triggers.action.trigger.remote_command_finished")
        process_result(raw_command, Vagrant::Util::Subprocess::Result.new(exit_code, @buffer[:stdout], @buffer[:stderr]), options)
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
        new_path  = ENV["VAGRANT_INSTALLER_ENV"] ? ENV["PATH"].gsub(/#{Regexp.quote(ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"])}.*?#{Regexp.quote(File::PATH_SEPARATOR)}/, "") : ENV["PATH"]
        new_path += Array(@options[:append_to_path]).map { |dir| "#{File::PATH_SEPARATOR}#{dir}" }.join
        ENV["PATH"] = new_path
        @logger.debug("PATH modified: #{ENV["PATH"]}")

        # Add the VAGRANT_NO_TRIGGERS variable to avoid loops
        ENV["VAGRANT_NO_TRIGGERS"] = "1"

        # Skip the subprocess jailbreak introduced in vagrant 1.7.3
        ENV["VAGRANT_SKIP_SUBPROCESS_JAILBREAK"] = "1"
      end

      def process_result(command, result, options)
        if result.exit_code != 0 && !options[:force]
          raise Errors::CommandFailed, :command => command, :stderr => result.stderr
        end
        result.stdout
      end

      # This is a custom version of Shellwords.shellsplit adapted for handling MS-DOS commands.
      #
      # Basically escape sequences are left intact if the platform is Windows.
      def shellsplit(line)
        words = []
        field = ''
        line.scan(/\G\s*(?>([^\s\\\'\"]+)|'([^\']*)'|"((?:[^\"\\]|\\.)*)"|(\\.?)|(\S))(\s|\z)?/) do |word, sq, dq, esc, garbage, sep|
          raise ArgumentError, "Unmatched double quote: #{line.inspect}" if garbage
          token = (word || sq || (dq || esc))
          token.gsub!(/\\(.)/, '\1') unless Vagrant::Util::Platform.windows?
          field << token
          if sep
            words << field
            field = ''
          end
        end
        words
      end
    end
  end
end
