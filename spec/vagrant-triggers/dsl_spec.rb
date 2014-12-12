require "fileutils"
require "spec_helper"

describe VagrantPlugins::Triggers::DSL do
  let(:result) { double("result", :exit_code => 0, :stderr => stderr) }
  let(:stderr) { double("stderr") }

  let(:machine) { double("machine", :ui => ui) }
  let(:ui)      { double("ui", :info => info) }
  let(:info)    { double("info") }

  before do
    @command = "foo"
    @dsl     = described_class.new(machine, {})

    result.stub(:stdout => "Some output")
  end

  context ":vm option" do
    before do
      machine.stub(:name => :vm1)
    end

    it "should raise no exception when :vm option match" do
      options = { :vm => "vm1" }
      expect { described_class.new(machine, options) }.not_to raise_error()
    end

    it "should raise NotMatchingMachine when :vm option doesn't match" do
      options = { :vm => "vm2" }
      expect { described_class.new(machine, options) }.to raise_error(VagrantPlugins::Triggers::Errors::NotMatchingMachine)
    end

    it "should raise no exception when :vm option is an array and one of the elements match" do
      options = { :vm => ["vm1", "vm2"] }
      expect { described_class.new(machine, options) }.not_to raise_error()
    end

    it "should raise NotMatchingMachine when :vm option is an array and no element match" do
      options = { :vm => ["vm2", "vm3"] }
      expect { described_class.new(machine, options) }.to raise_error(VagrantPlugins::Triggers::Errors::NotMatchingMachine)
    end

    it "should raise no exception when :vm option is a regex and the pattern match" do
      options = { :vm => /^vm/ }
      expect { described_class.new(machine, options) }.not_to raise_error()
    end

    it "should raise NotMatchingMachine when :vm option is a regex and the pattern doesn't match" do
      options = { :vm => /staging/ }
      expect { described_class.new(machine, options) }.to raise_error(VagrantPlugins::Triggers::Errors::NotMatchingMachine)
    end
  end

  context "error" do
    it "should raise a DSL error on UI error" do
      ui.should_receive(:error).with("Error message")
      expect { @dsl.error("Error message") }.to raise_error(VagrantPlugins::Triggers::Errors::DSLError)
    end
  end

  context "method missing" do
    it "acts as proxy if the ui object respond to the called method" do
      ui.stub(:foo).and_return("bar")
      expect(@dsl.foo).to eq("bar")
    end
  end

  context "run a regular command" do
    before do
      Vagrant::Util::Subprocess.stub(:execute => result)
    end

    it "should raise an error if executed command exits with non-zero code" do
      result.stub(:exit_code => 1)
      expect { @dsl.run(@command) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandFailed)
    end

    it "shouldn't raise an error if executed command exits with non-zero code but :force option was specified" do
      dsl = described_class.new(machine, :force => true)
      result.stub(:exit_code => 1)
      expect { dsl.run(@command) }.not_to raise_error()
    end

    it "should display output if :stdout option was specified" do
      dsl = described_class.new(machine, :stdout => true)
      ui.should_receive(:info).with(/Some output/)
      dsl.run(@command)
    end

    it "should pass VAGRANT_NO_TRIGGERS environment variable to the command" do
      Vagrant::Util::Subprocess.should_receive(:execute) do |command|
        expect(ENV).to have_key("VAGRANT_NO_TRIGGERS")
        result
      end
      @dsl.run(@command)
    end
  end

  context "run a command not in the PATH" do
    before do
      @tmp_dir = Vagrant::Util::Platform.windows? ? ENV["USERPROFILE"] : ENV["HOME"]
      File.open("#{@tmp_dir}/#{@command}", "w+", 0700) { |file| }
      File.stub(:executable? => false)
      File.stub(:executable?).with("#{@tmp_dir}/#{@command}").and_return(true)
    end

    after do
      File.delete("#{@tmp_dir}/#{@command}")
    end

    it "should raise a CommandUnavailable error by default" do
      expect { @dsl.run(@command) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandUnavailable)
    end

    it "should raise a CommandUnavailable error on Windows" do
      Vagrant::Util::Platform.stub(:windows? => true)
      expect { @dsl.run(@command) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandUnavailable)
    end

    it "should honor the :append_to_path option and restore original path after execution" do
      dsl = described_class.new(machine, :append_to_path => @tmp_dir)
      original_path = ENV["PATH"]
      dsl.run(@command)
      expect(ENV["PATH"]).to eq(original_path)
    end

    it "should accept an array for the :append_to_path option" do
      dsl = described_class.new(machine, :append_to_path => [@tmp_dir, @tmp_dir])
      expect { dsl.run(@command) }.not_to raise_error()
    end
  end

  context "run a command simulating the Vagrant environment" do
    before do
      @original_path                        = ENV["PATH"]
      ENV["VAGRANT_INSTALLER_ENV"]          = "1"
      ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"] = Vagrant::Util::Platform.windows? ? ENV["USERPROFILE"] : ENV["HOME"]
      ENV["GEM_HOME"]                       = "#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}/gems"
      ENV["GEM_PATH"]                       = ENV["GEM_HOME"]
      ENV["GEMRC"]                          = "#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}/etc/gemrc"
      ENV["PATH"]                           = "#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}/bin:#{ENV["PATH"]}"
      ENV["RUBYOPT"]                        = "-rbundler/setup"
    end

    context "with a command which is present into the Vagrant embedded dir" do
      before do
        Dir.mkdir("#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}/bin")
        File.open("#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}/bin/#{@command}", "w+", 0700) { |file| }
      end

      it "should raise a CommandUnavailable error" do
        expect { @dsl.run(@command) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandUnavailable)
      end

      after do
        FileUtils.rm_rf("#{ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"]}/bin")
      end
    end

    ["BUNDLE_BIN_PATH", "BUNDLE_GEMFILE", "GEM_PATH", "GEMRC"].each do |env_var|
      it "should not pass #{env_var} to the executed command" do
        Vagrant::Util::Subprocess.should_receive(:execute) do |command|
          expect(ENV).not_to have_key(env_var)
          result
        end
        @dsl.run(@command)
      end
    end

    it "should remove bundler settings from RUBYOPT" do
      Vagrant::Util::Subprocess.should_receive(:execute) do |command|
        expect(ENV["RUBYOPT"]).to eq("")
        result
      end
      @dsl.run(@command)
    end

    after do
      ENV["EMBEDDED_DIR"] = nil
      ENV["GEM_HOME"]     = nil
      ENV["GEM_PATH"]     = nil
      ENV["GEMRC"]        = nil
      ENV["PATH"]         = @original_path
      ENV["RUBYOPT"]      = nil
    end
  end

  context "run a remote command" do
    before do
      Vagrant::Util::Subprocess::Result.stub(:new => result)
      machine.stub_chain(:communicate, :sudo).and_return(0)
    end

    it "should raise an error if executed command exits with non-zero code" do
      result.stub(:exit_code => 1)
      expect { @dsl.run_remote(@command) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandFailed)
    end

    it "shouldn't raise an error if executed command exits with non-zero code but :force option was specified" do
      dsl = described_class.new(machine, :force => true)
      result.stub(:exit_code => 1)
      expect { dsl.run_remote(@command) }.not_to raise_error()
    end

    it "should display output if :stdout option was specified" do
      dsl = described_class.new(machine, :stdout => true)
      ui.should_receive(:info).with(/Some output/)
      dsl.run_remote(@command)
    end
  end
end
