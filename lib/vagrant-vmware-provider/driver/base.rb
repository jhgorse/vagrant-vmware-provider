require 'log4r'

require 'vagrant/util/busy'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'

ENV['VM_RUN_PATH'] = "/Applications/VMware Fusion.app/Contents/Library/vmrun"

module VagrantPlugins
  module VMwareProvider
    module Driver
      # Base class for all VirtualBox drivers.
      #
      # This class provides useful tools for things such as executing
      # VMRun and handling SIGINTs and so on.
      class Base
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        def initialize
          @logger = Log4r::Logger.new("vagrant::provider::virtualbox::base")

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          # Set the path to VBoxManage
          @vmrun_path = "vmrun"

          if Vagrant::Util::Platform.windows? || Vagrant::Util::Platform.cygwin?
            @logger.debug("Windows. Trying VBOX_INSTALL_PATH for VBoxManage")

            # On Windows, we use the VBOX_INSTALL_PATH environmental
            # variable to find VBoxManage.
            if ENV.key?("VBOX_INSTALL_PATH") ||
              ENV.key?("VBOX_MSI_INSTALL_PATH")
              # Get the path.
              path = ENV["VBOX_INSTALL_PATH"] || ENV["VBOX_MSI_INSTALL_PATH"]
              @logger.debug("VBOX_INSTALL_PATH value: #{path}")

              # There can actually be multiple paths in here, so we need to
              # split by the separator ";" and see which is a good one.
              path.split(";").each do |single|
                # Make sure it ends with a \
                single += "\\" if !single.end_with?("\\")

                # If the executable exists, then set it as the main path
                # and break out
                vmrun = "#{single}VBoxManage.exe"
                if File.file?(vboxmanage)
                  @vmrun_path = Vagrant::Util::Platform.cygwin_windows_path(vmrun)
                  break
                end
              end
            end
          else
            @vmrun_path = ENV['VM_RUN_PATH']
          end

          @logger.info("vmrun path: #{@vmrun_path}")
        end

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
        end

        # Execute a raw command straight through to VMRun.
        #
        # Accepts a retryable: true option if the command should be retried
        # upon failure.
        #
        # Raises a VBoxManage error if it fails.
        #
        # @param [Array] command Command to execute.
        def execute_command(command)
        end

        # Execute the given subcommand for VMRun and return the output.
        def execute(*command, &block)
          # Get the options hash if it exists
          opts = {}
          opts = command.pop if command.last.is_a?(Hash)

          tries = 0
          tries = 3 if opts[:retryable]

          # Variable to store our execution result
          r = nil

          retryable(on: Vagrant::Errors::VBoxManageError, tries: tries, sleep: 1) do
            # If there is an error with VBoxManage, this gets set to true
            errored = false

            # Execute the command
            r = raw(*command, &block)

            # If the command was a failure, then raise an exception that is
            # nicely handled by Vagrant.
            if r.exit_code != 0
              if @interrupted
                @logger.info("Exit code != 0, but interrupted. Ignoring.")
              else
                errored = true
              end
            end

            # If there was an error running VBoxManage, show the error and the
            # output.
            if errored
              raise Vagrant::Errors::VBoxManageError,
                command: command.inspect,
                stderr:  r.stderr,
                stdout:  r.stdout
            end
          end

          # Return the output, making sure to replace any Windows-style
          # newlines with Unix-style.
          r.stdout.gsub("\r\n", "\n")
        end


        # Executes a command and returns the raw result object.
        def raw(*command, &block)
          int_callback = lambda do
            @interrupted = true

            # We have to execute this in a thread due to trap contexts
            # and locks.
            Thread.new { @logger.info("Interrupted.") }.join
          end

          # Append in the options for subprocess
          command << { notify: [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(@vmrun_path, *command, &block)
          end
        end


      end
    end
  end
end

