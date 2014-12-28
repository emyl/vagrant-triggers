module VagrantPlugins
  module Triggers
    module Config
      # Autoload farm
      config_root = Pathname.new(File.expand_path("../config", __FILE__))
      autoload :Provisioner, config_root.join("provisioner")
      autoload :Trigger,     config_root.join("trigger")
    end
  end
end
