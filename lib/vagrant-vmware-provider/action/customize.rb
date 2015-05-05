module VagrantPlugins
  module VMwareProvider
    module Action
      class Customize
        def initialize(app, env, event)
          @app = app
          @event = event
        end

        def call(env)
          @app.call(env)
        end
      end
    end
  end
end
