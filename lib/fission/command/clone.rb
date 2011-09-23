module Fission
  class Command
    class Clone < Command

      def initialize(args=[])
        super
        @options.start = false
      end

      def execute
        option_parser.parse! @args

        unless @args.count > 1
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for clone command", 1
        end

        source_vm = @args.first
        target_vm = @args[1]


        unless Fission::VM.exists? source_vm
            Fission.ui.output_and_exit "Unable to find the source vm #{source_vm} (#{Fission::VM.path(source_vm)})", 1 
        end


        if Fission::VM.exists? target_vm
            Fission::ui.output_and_exit "The target vm #{target_vm} already exists", 1
        end

        clone_task = Fission::VM.clone source_vm, target_vm

        if clone_task.successful?
          Fission.ui.output ''
          Fission.ui.output 'Clone complete!'

          if @options.start
            Fission.ui.output "Starting '#{target_vm}'"
            vm = Fission::VM.new target_vm

            start_task = vm.start

            if start_task.successful?
              Fission.ui.output "VM '#{target_vm}' started"
            else
              Fission.ui.output_and_exit "There was an error starting the VM.  The error was:\n#{start_task.output}", start_task.code
            end
          end
        else
          Fission.ui.output_and_exit "There was an error cloning the VM.  The error was:\n#{clone_task.output}", clone_task.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nclone usage: fission clone source_vm target_vm [options]"

          opts.on '--start', 'Start the VM after cloning' do
            @options.start = true
          end
        end

        optparse
      end

    end
  end
end
