require 'vagrant'

module VagrantPlugins
  module VMwareProvider
    module Errors
      # Initialize main error class.
      class VMwareError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_desktop.errors')
      end
      # Set key for Rsync errors.
      class RsyncError < VMwareError
        error_key(:rsync_error)
      end
      # Set key for Mkdir errors.
      class MkdirError < VMwareError
        error_key(:mkdir_error)
      end
      # Set key for VCenterOldVersion errors.
      class VmwareInvalidVersion < VMwareError
        error_key(:vmware_invalid_version)
      end
      # Set key for VCenterOldVersion errors.
      class VmwareBoxNotDetected < VMwareError
        error_key(:vmware_box_not_detected)
      end
    end
  end
end
