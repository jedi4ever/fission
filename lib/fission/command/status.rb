module Fission
  class Command
    class Status < Command

      def initialize(args=[])
        super
      end

      def execute
        response = Fission::VM.all
        if response.successful?
          all_vms = response.data
        end

        response = Fission::VM.all_running
        if response.successful?
          all_running_vms = response.data
        else
          Fission.ui.output_and_exit "There was an error getting the list of running VMs.  The error was:\n#{response.output}", response.code
        end

        longest_vm_name = all_vms.max { |a,b| a.length <=> b.length }

        VM.all.each do |vmname|
          vm=VM.new(vmname)
          status = vm.state
          Fission.ui.output_printf "%-#{longest_vm_name.length}s   %s\n", vmname, "["+status+"]"
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nstatus usage: fission status"
        end

        optparse
      end

    end
  end
end
