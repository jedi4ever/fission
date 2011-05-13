require File.expand_path('../../spec_helper.rb', __FILE__)
require 'yaml'

describe Fission::Config do
  describe "init" do
    it "should use the fusion default dir for vm_dir" do
      @config = Fission::Config.new
      @config.attributes['vm_dir'].should == '~/Documents/Virtual\ Machines.localized/'
    end

    it "should use the user specified dir in ~/.fissionrc" do
      FakeFS do
        File.open('~/.fissionrc', 'w') { |f| f.puts YAML.dump({ 'vm_dir' => '/var/tmp/foo' })}

        @config = Fission::Config.new
        @config.attributes['vm_dir'].should == '/var/tmp/foo'
      end
    end

  end

end