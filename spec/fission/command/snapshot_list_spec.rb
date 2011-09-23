require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotList do
  before do
    @target_vm = ['foo']
    @vm_mock = mock('vm_mock')
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @exists_response_mock = mock('exists_response')
    @snap_list_response_mock = mock('snap_list_response')
  end

  describe 'execute' do
    it "should output an error and the help when no VM argument is passed in" do
      Fission::Command::SnapshotList.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotList.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot list command/
    end

    it "should output an error and exit if it can't find the target vm" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(false)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)

      lambda {
        command = Fission::Command::SnapshotList.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@target_vm.first}/
    end

    it 'should output the list of snapshots if any exist' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      @snap_list_response_mock.should_receive(:successful?).and_return(true)
      @snap_list_response_mock.should_receive(:data).and_return(['snap 1', 'snap 2', 'snap 3'])
      @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)
      command = Fission::Command::SnapshotList.new @target_vm
      command.execute

      @string_io.string.should match /snap 1\nsnap 2\nsnap 3\n/
    end

    it 'should output that it could not find any snapshots if none exist' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      @snap_list_response_mock.should_receive(:successful?).and_return(true)
      @snap_list_response_mock.should_receive(:data).and_return([])
      @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)
      command = Fission::Command::SnapshotList.new @target_vm
      command.execute

      @string_io.string.should match /No snapshots found for VM '#{@target_vm.first}'/
    end

    it 'should output an error and exit if there was an error getting the list of snapshots' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      @snap_list_response_mock.should_receive(:successful?).and_return(false)
      @snap_list_response_mock.should_receive(:code).and_return(1)
      @snap_list_response_mock.should_receive(:output).and_return('it blew up')
      @vm_mock.should_receive(:snapshots).and_return(@snap_list_response_mock)
      command = Fission::Command::SnapshotList.new @target_vm
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /There was an error listing the snapshots.+it blew up.+/m
    end

  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotList.help

      output.should match /snapshot list/
    end
  end
end
