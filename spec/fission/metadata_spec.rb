require File.expand_path('../../spec_helper.rb', __FILE__)

describe Fission::Metadata do
  before do
    @plist_mock = mock('plist_mock')
    @plist_file_path = Fission.config.attributes['plist_file']
    @metadata = Fission::Metadata.new
  end

  describe 'load' do
    it 'should load the existing data' do
      plist = {'vm_list' => ['1', '2', '3']}
      CFPropertyList::List.should_receive(:new).
                           with(:file => @plist_file_path).
                           and_return(@plist_mock)
      @plist_mock.stub!(:value).and_return(plist)
      CFPropertyList.should_receive(:native_types).with(plist).
                                                   and_return([1, 2, 3])
      @metadata.load
      @metadata.content.should == [1, 2, 3]
    end
  end

  describe 'delete_vm_restart_document' do
    before do
      @data = { 'PLRestartDocumentPaths' => ['/vm/foo.vmwarevm', '/vm/bar.vmwarevm']}
      @metadata.content = @data
    end

    it 'should remove the vm item from the list if the vm path is in the list' do
      @metadata.delete_vm_restart_document(Fission::VM.path('foo'))
      @metadata.content.should == { 'PLRestartDocumentPaths' => ['/vm/bar.vmwarevm']}
    end

    it 'should not doing anything if the vm is not in the list' do
      @metadata.delete_vm_restart_document(Fission::VM.path('baz'))
      @metadata.content.should == @data
    end

    it 'should not do anything if the restart document list does not exist' do
      other_data = { 'OtherConfigItem' => ['foo', 'bar']}
      @metadata.content = other_data
      @metadata.delete_vm_restart_document(Fission::VM.path('foo'))
      @metadata.content.should == other_data
    end
  end

  describe 'delete_vm_favorite_entry' do
    before do
      @data = { 'VMFavoritesListDefaults2' => [{'path' => '/vm/foo.vmwarevm'}] }
      @metadata.content = @data
    end

    it 'should remove the vm item from the list' do
      @metadata.delete_vm_favorite_entry(Fission::VM.path('foo'))
      @metadata.content.should == { 'VMFavoritesListDefaults2' => [] }
    end

    it 'should not do anything if the vm is not in the list' do
      @metadata.delete_vm_favorite_entry(Fission::VM.path('bar'))
      @metadata.content.should == @data
    end
  end

  describe 'self.delete_vm_info' do
    before do
      @md_mock = mock('metadata_mock')
      @md_mock.should_receive(:load)
      @md_mock.should_receive(:save)
      Fission::Metadata.stub!(:new).and_return(@md_mock)
    end

    it 'should remove the vm from the restart document list' do
      @md_mock.should_receive(:delete_vm_restart_document).with('/vm/foo.vmwarevm')
      @md_mock.stub!(:delete_vm_favorite_entry)
      Fission::Metadata.delete_vm_info(Fission::VM.path('foo'))
    end

    it 'should remove the vm from the favorite list' do
      @md_mock.should_receive(:delete_vm_favorite_entry).with('/vm/foo.vmwarevm')
      @md_mock.stub!(:delete_vm_restart_document)
      Fission::Metadata.delete_vm_info(Fission::VM.path('foo'))
    end
  end

  describe 'save' do
    it 'should save the data' do
      CFPropertyList::List.should_receive(:new).and_return(@plist_mock)
      CFPropertyList.should_receive(:guess).with([1, 2, 3]).
                                           and_return(['1', '2', '3'])

      @plist_mock.should_receive(:value=).with(['1', '2', '3'])
      @plist_mock.should_receive(:save).
                  with(@plist_file_path, CFPropertyList::List::FORMAT_BINARY)

      @metadata.content = [1, 2, 3]
      @metadata.save
    end
  end
end
