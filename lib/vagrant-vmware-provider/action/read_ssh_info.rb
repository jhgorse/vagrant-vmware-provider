require "log4r"

module VagrantPlugins
  module VMwareProvider
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_vmware_provider::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          address = env[:machine].provider.driver.ssh_info()
          if not address or address == ''
            @logger.debug("could not find booted guest ip address")
          end
          
          env[:nfs_machine_ip] = address

          return { :host => address, :port => 22 }
        end
      end
    end
  end
end
