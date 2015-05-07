require 'pp'

module VagrantPlugins
  module VMwareProvider 
    module Action
      class Boot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          pp @env[:machine].provider_config
          pp @env[:machine].provider_config.gui
          boot_mode = @env[:machine].provider_config.gui ? "gui" : "nogui"

          # Start up the VM and wait for it to boot.
          env[:ui].info I18n.t("vagrant.actions.vm.boot.booting")
          env[:machine].provider.driver.start(boot_mode)

          @app.call(env)
        end
      end
    end
  end
end
