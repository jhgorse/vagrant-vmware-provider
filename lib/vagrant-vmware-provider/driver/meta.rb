require "forwardable"

require "log4r"

require "vagrant/util/retryable"

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module VMwareProvider
    module Driver
      class Meta < Base
        # This is raised if the VM is not found when initializing a driver
        # with a UUID.
        class VMNotFound < StandardError; end

        # We use forwardable to do all our driver forwarding
        extend Forwardable

        # The UUID of the virtual machine we represent
        attr_reader :vmx_file

        # The version of virtualbox that is running.
        attr_reader :version

        include Vagrant::Util::Retryable

        def initialize(vmx_file=nil)
          # Setup the base
          super()

          @logger = Log4r::Logger.new("vagrant::provider::vmware::meta")
          @vmx_file = Pathname.new(vmx_file) if vmx_file

          # Read and assign the version of VirtualBox we know which
          # specific driver to instantiate.
          driver_klass = Version_7_0

          @logger.info("Using VMWare driver: #{driver_klass}")
          @driver = driver_klass.new(@vmx_file)

          if @vmx_file
            # Verify the VM exists, and if it doesn't, then don't worry
            # about it (mark the UUID as nil)
            raise VMNotFound if !@driver.vm_exists?(@vmx_file)
          end
        end

        def_delegators :@driver, 
          :delete,
          :halt,
          :clone_vm,
          :read_state,
          :ssh_info,
          :start,
          :suspend,
          :verify!,
          :vm_exists?

        protected

      end
    end
  end
end
