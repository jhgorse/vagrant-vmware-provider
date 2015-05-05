module VagrantPlugins
  module VMwareProvider
    module Action
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               name: env[:machine].box.name)

          # Import the virtual machine
          data_dir = env[:machine].data_dir
          if ENV.has_key?("VAGRANT_VMWARE_CLONE_DIRECTORY")
            env_dir = Pathname.new(ENV["VAGRANT_VMWARE_CLONE_DIRECTORY"])
            data_dir = env_dir if env_dir.directory?
          end
          vmx_output = data_dir.join(env[:machine].name.to_s).join(env[:machine].name.to_s + ".vmx").to_s

          box_dir = env[:machine].box.directory
          vmx_source = box_dir.join(Dir[box_dir + "\*.vmxf"].first).to_s

          env[:machine].id = env[:machine].provider.driver.clone_vm(vmx_source, vmx_output) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Flag as erroneous and return if import failed
          raise Vagrant::Errors::VMImportFailure if !env[:machine].id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if env[:machine].state.id != :not_created
            return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

            # If we're not supposed to destroy on error then just return
            return if !env[:destroy_on_error]

            # Interrupted, destroy the VM. We note that we don't want to
            # validate the configuration here, and we don't want to confirm
            # we want to destroy.
            destroy_env = env.clone
            destroy_env[:config_validate] = false
            destroy_env[:force_confirm_destroy] = true
            env[:action_runner].run(Action.action_destroy, destroy_env)
          end
        end
      end
    end
  end
end
