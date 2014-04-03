require "fileutils"
require "spec_helper"

describe VagrantPlugins::Triggers::DSL do
  let(:result) { double("result", :exit_code => 0, :stderr => stderr) }
  let(:stderr) { double("stderr") }

  let(:ui)     { double("ui", :info => info) }
  let(:info)   { double("info") }

  before do
    @command = "foo"
    @dsl     = described_class.new(ui, {})
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
      dsl = described_class.new(ui, :force => true)
      result.stub(:exit_code => 1)
      expect { dsl.run(@command) }.not_to raise_error()
    end

    it "should display output if :stdout option was specified" do
      dsl = described_class.new(ui, :stdout => true)
      result.stub(:stdout => "Some output")
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
      dsl = described_class.new(ui, :append_to_path => @tmp_dir)
      original_path = ENV["PATH"]
      dsl.run(@command)
      expect(ENV["PATH"]).to eq(original_path)
    end

    it "should accept an array for the :append_to_path option" do
      dsl = described_class.new(ui, :append_to_path => [@tmp_dir, @tmp_dir])
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

    ["GEM_HOME", "GEM_PATH", "GEMRC"].each do |env_var|
      it "should not pass #{env_var} to the executed command" do
        Vagrant::Util::Subprocess.should_receive(:execute) do |command|
          expect(ENV).not_to have_key(env_var)
          result
        end
        @dsl.run(@command)
      end
    end

    after do
      ENV["EMBEDDED_DIR"] = nil
      ENV["GEM_HOME"]     = nil
      ENV["GEM_PATH"]     = nil
      ENV["GEMRC"]        = nil
      ENV["PATH"]         = @original_path
    end
  end
end
