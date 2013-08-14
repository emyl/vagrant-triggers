module VagrantPlugins
  module Triggers
    module Errors
      class VagrantTriggerError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_triggers.errors")
      end

      class CommandFailed < VagrantTriggerError
        error_key(:command_failed)
      end
    end
  end
end