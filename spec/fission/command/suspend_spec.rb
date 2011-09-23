require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::Suspend do
  before do
    @vm_info = ['foo']
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @all_running_response_mock = mock('all_running_response')
    @exists_response_mock = mock('exists_response')
    @suspend_response_mock = mock('suspend_response')
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::Suspend.should_receive(:help)

      lambda {
        command = Fission::Command::Suspend.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for suspend command/
    end

    it "should output an error and exit if it can't find the VM" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(false)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)

      lambda {
        command = Fission::Command::Suspend.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@vm_info.first}/
    end


    it "should output and exit if the vm is not running" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([])
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      lambda {
        command = Fission::Command::Suspend.new @vm_info
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /VM '#{@vm_info.first}' is not running/
    end

    it 'should try to suspend the vm if it is running' do
      @vm_mock = mock('vm_mock')
      @all_running_response_mock.should_receive(:successful?).and_return(true)
      @all_running_response_mock.should_receive(:data).and_return([@vm_info.first])
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)
      Fission::VM.should_receive(:new).with(@vm_info.first).and_return(@vm_mock)
      @suspend_response_mock.should_receive(:successful?).and_return(true)
      @vm_mock.should_receive(:suspend).and_return(@suspend_response_mock)

      command = Fission::Command::Suspend.new @vm_info
      command.execute

      @string_io.string.should match /Suspending '#{@vm_info.first}'/
      @string_io.string.should match /VM '#{@vm_info.first}' suspended/
    end

    it 'should print an error and exit if there was an error getting the list of running VMs' do
      @vm_mock = mock('vm_mock')
      @all_running_response_mock.should_receive(:successful?).and_return(false)
      @all_running_response_mock.should_receive(:code).and_return(1)
      @all_running_response_mock.should_receive(:output).and_return('it blew up')
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@vm_info.first).
                                           and_return(@exists_response_mock)
      Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

      command = Fission::Command::Suspend.new @vm_info
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /There was an error getting the list of running VMs.+it blew up/m
    end

    describe 'with --all' do
      it 'should suspend all running VMs' do
        @vm_mock_1 = mock('vm_mock_1')
        @vm_mock_2 = mock('vm_mock_2')

        vm_items = {'vm_1' => @vm_mock_1,
                    'vm_2' => @vm_mock_2
        }

        @all_running_response_mock.should_receive(:successful?).and_return(true)
        @all_running_response_mock.should_receive(:data).and_return(vm_items.keys)
        Fission::VM.should_receive(:all_running).and_return(@all_running_response_mock)

        vm_items.each_pair do |name, mock|
          @suspend_response_mock.should_receive(:successful?).and_return(true)
          mock.should_receive(:suspend).and_return(@suspend_response_mock)
          Fission::VM.should_receive(:new).with(name).and_return(mock)
        end

        command = Fission::Command::Suspend.new ['--all']
        command.execute

        vm_items.keys.each do |vm|
          @string_io.string.should match /Suspending '#{vm}'/
          @string_io.string.should match /VM '#{vm}' suspended/
        end
      end
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::Suspend.help

      output.should match /suspend \[vm \| --all\]/
    end
  end
end
