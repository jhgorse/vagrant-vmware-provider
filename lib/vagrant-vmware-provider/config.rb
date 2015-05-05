require "vagrant"

module VagrantPlugins
  module VMwareProvider
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :memsize
      attr_accessor :number_of_virtual_cpus
      attr_accessor :vm_pc_enable
      attr_accessor :cores_per_socket
      attr_accessor :display_name
      attr_accessor :guest_os
      attr_accessor :gui

      def initialize()
      end

#      def merge(other)
#        super.tap do |result|
#        end
#      end

      def finalize!
        @memsize = system_memory / 2 unless @memsize
        @number_of_virtual_cpus = system_cores unless @number_of_virtual_cpus  
        @vm_pc_enable = "TRUE" unless @vm_pc_enable
        @cores_per_socket = system_cores unless @cores_per_socket

        true
      end

      def validate(machine)
        {"VMware Provider" => _detected_errors}
      end
      
      private
     
      def system_memory
        `sysctl -n hw.memsize`.chomp.to_i / 1024 / 1024
      end

      def system_cores
        `sysctl -n hw.physicalcpu`.chomp.to_i
      end
    end
  end
end
