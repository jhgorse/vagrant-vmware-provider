require "log4r"

module VagrantPlugins
  module VMwareProvider
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def self.usable?(raise_error=false)
        # Instantiate the driver, which will determine the VMware
        # version and all that, which checks for VMware being present
        Driver::Meta.new
        true
      rescue Errors::VmwareInvalidVersion
        raise if raise_error
        return false
      rescue Errors::VmwareBoxNotDetected
        raise if raise_error
        return false
      end

      def initialize(machine)
        @logger  = Log4r::Logger.new("vagrant::provider::vmware")
        @machine = machine

        # This method will load in our driver, so we call it now to
        # initialize it.
        machine_id_changed
      end

      # @see Vagrant::Plugin::V1::Provider#action
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      # If the machine ID changed, then we need to rebuild our underlying
      # driver.
      def machine_id_changed
        id = @machine.id

        begin
          @logger.debug("Instantiating the driver for machine ID: #{@machine.id.inspect}")
          @driver = Driver::Meta.new(id)
        rescue Driver::Meta::VMNotFound
          # The virtual machine doesn't exist, so we probably have a stale
          # ID. Just clear the id out of the machine and reload it.
          @logger.debug("VM not found! Clearing saved machine ID and reloading.")
          id = nil
          retry
        end
      end

      def ssh_info
        # If the VM is not running that we can't possibly SSH into it
        return nil if state.id != :running

        # Run a custom action called "read_ssh_info" which does what it
        # says and puts the resulting SSH info into the `:machine_ssh_info`
        # key in the environment.
        env = @machine.action(:read_ssh_info)
        env[:machine_ssh_info]
      end

      def state
        # Determine the ID of the state here.
        state_id = nil
        state_id = :not_created if !@driver.vmx_file
        state_id = @driver.read_state if !state_id
        state_id = :unknown if !state_id

        # Translate into short/long descriptions
        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("vagrant.commands.status.#{state_id}")

        # If we're not created, then specify the special ID flag
        if state_id == :not_created
          state_id = Vagrant::MachineState::NOT_CREATED_ID
        end

        # Return the state
        Vagrant::MachineState.new(state_id, short, long)
      end

      # Returns a human-friendly string version of this provider which
      # includes the machine's ID that this provider represents, if it
      # has one.
      #
      # @return [String]
      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "VMWare (#{id})"
      end
    end
  end
end
