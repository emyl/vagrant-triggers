module VagrantPlugins
  module Triggers
    module Errors
      class VagrantTriggerError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_triggers.errors")
      end

      class CommandFailed < VagrantTriggerError
        error_key(:command_failed)
      end

      class CommandUnavailable < VagrantTriggerError
        error_key(:command_unavailable)
      end

      class DSLError < VagrantTriggerError
        error_key(:dsl_error)
      end

      class NotMatchingMachine < VagrantTriggerError
      end
    end
  end
end
