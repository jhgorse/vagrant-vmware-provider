module VagrantPlugins
  module VMwareProvider
    module Action
      class Customize
        def initialize(app, env, event)
          @app = app
          @event = event
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.customize.running", event)
          env[:machine].provider_config.vmx.each do |key, value|
            env[:machine].provider.driver.customize(key, value)
          end

          @app.call(env)
        end
      end
    end
  end
end
