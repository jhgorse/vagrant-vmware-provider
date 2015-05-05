require "vagrant"

module VagrantPlugins
  module VMwareProvider
    class Plugin < Vagrant.plugin("2")
      name "Vagrant VMWware Provider"
      description <<-EOF
      The VMWare Provider allows Vagrant to manage and control
      VMWare based virtual machines.
      EOF

      provider(:vmware_desktop) do
        require File.expand_path("../provider", __FILE__)
        Provider
      end

      config(:vmware_desktop, :provider) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      # Add vagrant share support
      provider_capability('vmware_desktop', 'public_address') do
        require_relative 'cap/public_address'
        Cap::PublicAddress
      end
    end

    autoload :Action, File.expand_path("../action", __FILE__)

    # Drop some autoloads in here to optimize the performance of loading
    # our drivers only when they are needed.
    module Driver
      autoload :Meta, File.expand_path("../driver/meta", __FILE__)
      autoload :Version_7_0, File.expand_path("../driver/version_7_0", __FILE__)
      autoload :VMX, File.expand_path("../driver/vmx", __FILE__)
    end
  end
end
