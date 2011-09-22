require File.expand_path('../../../spec_helper.rb', __FILE__)

describe Fission::Command::SnapshotRevert do
  before do
    @target_vm = ['foo']
    @vm_mock = mock('vm_mock')
    Fission::VM.stub!(:new).and_return(@vm_mock)
    @string_io = StringIO.new
    Fission.stub!(:ui).and_return(Fission::UI.new(@string_io))
    @exists_response_mock = mock('exists_response')
    @snap_revert_response_mock = mock('snap_revert_response')
  end

  describe 'execute' do
    it "should output an error and the help when no vm name is passed in" do
      Fission::Command::SnapshotRevert.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotRevert.new
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot revert command/
    end

    it "should output an error and the help when no snapshot name is passed in" do
      Fission::Command::SnapshotRevert.should_receive(:help)

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Incorrect arguments for snapshot revert command/
    end

    it "should output an error and exit if it can't find the target vm" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(false)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the VM #{@target_vm.first}/
    end

    it "should output an error and exit if it can't find the snapshot" do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      Fission::Fusion.should_receive(:is_running?).and_return(false)
      @vm_mock.should_receive(:snapshots).and_return([])

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Unable to find the snapshot 'snap_1'/
    end

    it 'should output an error and exit if the fusion app is running' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      Fission::Fusion.should_receive(:is_running?).and_return(true)

      lambda {
        command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
        command.execute
      }.should raise_error SystemExit

      @string_io.string.should match /Fusion GUI is currently running/
      @string_io.string.should match /Please exit the Fusion GUI and try again/
    end

    it 'should output an error and exit if there was an error getting the list of running VMs'

    it 'should revert to the snapshot with the provided name' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      Fission::Fusion.should_receive(:is_running?).and_return(false)
      @snap_revert_response_mock.should_receive(:successful?).and_return(true)
      @vm_mock.should_receive(:snapshots).and_return(['snap_1', 'snap_2'])
      @vm_mock.should_receive(:revert_to_snapshot).with('snap_1').and_return(@snap_revert_response_mock)
      command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
      command.execute

      @string_io.string.should match /Reverting to snapshot 'snap_1'/
      @string_io.string.should match /Reverted to snapshot 'snap_1'/
    end

    it 'should output an error and exit if there was an error reverting to the snapshot' do
      @exists_response_mock.should_receive(:successful?).and_return(true)
      @exists_response_mock.should_receive(:data).and_return(true)
      Fission::VM.should_receive(:exists?).with(@target_vm.first).
                                           and_return(@exists_response_mock)
      Fission::Fusion.should_receive(:is_running?).and_return(false)
      @snap_revert_response_mock.should_receive(:successful?).and_return(false)
      @snap_revert_response_mock.should_receive(:code).and_return(1)
      @snap_revert_response_mock.should_receive(:output).and_return('it blew up')
      @vm_mock.should_receive(:snapshots).and_return(['snap_1', 'snap_2'])
      @vm_mock.should_receive(:revert_to_snapshot).with('snap_1').and_return(@snap_revert_response_mock)
      command = Fission::Command::SnapshotRevert.new @target_vm << 'snap_1'
      lambda { command.execute }.should raise_error SystemExit

      @string_io.string.should match /Reverting to snapshot 'snap_1'/
      @string_io.string.should match /There was an error reverting to the snapshot.+it blew up.+/m
    end
  end

  describe 'help' do
    it 'should output info for this command' do
      output = Fission::Command::SnapshotRevert.help

      output.should match /snapshot revert my_vm snapshot_1/
    end
  end
end
