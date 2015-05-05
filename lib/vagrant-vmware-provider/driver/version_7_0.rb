require 'log4r'

require "vagrant/util/platform"

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module VMwareProvider
    module Driver
      # Driver for VirtualBox 4.0.x
      class Version_7_0 < Base
        def initialize(vmx_file)
          super()

          @logger = Log4r::Logger.new("vagrant::provider::vmware_7_0")
          @vmx_file = vmx_file
        end

        def delete
          execute("deleteVM", @vmx_file.to_s)
        end

        def clone_vm(ovf)
          ovf = Vagrant::Util::Platform.cygwin_windows_path(ovf)

          @vmx_file.dirname.mkpath()

          output = ""
          total = ""
          last  = 0
          execute("clone", ovf, @vmx_file.to_s, "linked") do |type, data|
            if type == :stdout
              # Keep track of the stdout so that we can get the VM name
              output << data
            elsif type == :stderr
              # Append the data so we can see the full view
              total << data
            end
          end
          return @vmx_file.to_s
        end

        def halt
          execute("stop", @vmx_file.to_s, "hard")
        end

        def read_state
          vmx_filename = @vmx_file.to_s
          return :not_created if !vm_exists?(@vmx_file)
          output = execute("list")
          return :running if output =~ /#{vmx_filename}/

          vmx = Driver::VMX.new(vmx_filename)
          return :is_saved if vmx.data.has_key?("checkpoint.vmState")
          return :not_running
          nil
        end

        def resume
          @logger.debug("Resuming paused VM...")
          execute("start", @vmx_file.to_s, "nogui")
        end


        def start(mode)
          command = ["start", @vmx_file.to_s, mode.to_s]
          r = raw(*command)

          if r.exit_code == 0
            # Some systems return an exit code 1 for some reason. For that
            # we depend on the output.
            return true
          end

          # If we reached this point then it didn't work out.
          raise Vagrant::Errors::VBoxManageError,
            command: command.inspect,
            stderr: r.stderr
        end

        def ssh_info()
          execute("getGuestIPAddress", @vmx_file.to_s, "-wait").strip
        end

        def suspend
          execute("suspend", @vmx_file.to_s, "soft")
        end

        def valid_ip_address?(ip)
          # Filter out invalid IP addresses
          # GH-4658 VirtualBox can report an IP address of 0.0.0.0 for FreeBSD guests.
          if ip == "0.0.0.0"
            return false
          else
            return true
          end
        end

        def verify!
          # This command sometimes fails if kernel drivers aren't properly loaded
          # so we just run the command and verify that it succeeded.
          execute("list")
        end

        def vm_exists?(vmx_file)
          File.directory?(vmx_file.dirname()) && File.exist?(vmx_file)
        end

      end
    end
  end
end
