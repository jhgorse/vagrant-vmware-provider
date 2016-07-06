require "vagrant"

module VagrantPlugins
  module VMwareProvider
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :display_name
      attr_accessor :guest_os
      attr_accessor :gui
      attr_accessor :vmx

      def initialize()
        @gui = false
        @guest_os = UNSET_VALUE
        @vmx = {}
      end

      def memory=(size)
        # TODO: vmrun writeVariable "path_to.vmx" runtimeConfig memsize size.to_s
        # vbox: customize("pre-boot", ["modifyvm", :id, "--memory", size.to_s])
        #VagrantPlugins::VMwareProvider::Base::execute("writeVariable", @vmx, "runtimeConfig memsize ", size.to_s)
      end


      def merge(other)
        super.tap do |result|
          vmx = {}
          vmx.merge!(@vmx) if @vmx
          vmx.merge!(other.vmx) if other.vmx
          result.vmx = vmx if vmx
        end
      end

      def finalize!
        true
      end

      def validate(machine)
        {"VMware Provider" => _detected_errors}
      end

      private
    end
  end
end
