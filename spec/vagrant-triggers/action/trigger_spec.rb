require "spec_helper"

describe VagrantPlugins::Triggers::Action::Trigger do
  let(:app)            { lambda { |env| } }
  let(:env)            { { :action_name => action_name, :machine => machine, :machine_action => machine_action, :ui => ui } }
  let(:condition)      { double("condition") }
  let(:action_name)    { double("action_name") }
  let(:machine)        { double("machine") }
  let(:machine_action) { double("machine_action") }

  let(:ui)             { double("ui", :info => info) }
  let(:info)           { double("info") }

  let(:result)         { double("result", :exit_code => 0, :stderr => stderr) }
  let(:stderr)         { double("stderr") }

  before do
    @triggers = [ { :action => machine_action, :condition => condition, :options => { :execute => "foo" } } ]
    machine.stub_chain(:config, :trigger, :triggers).and_return(@triggers)
  end

  context "with a regular command" do
    before do
      Vagrant::Util::Subprocess.stub(:execute => result)
    end

    it "should skip :environment_load and :environment_unload actions" do
      [:environment_load, :environment_unload].each do |action|
        env.stub(:[]).with(:action_name).and_return(action)
        env.should_not_receive(:[]).with(:machine_action)
        described_class.new(app, env, condition).call(env)
      end
    end

    it "shouldn't fire if machine action is not defined" do
      env.stub(:[]).with(:action_name)
      env.stub(:[]).with(:machine_action).and_return(nil)
      env.should_not_receive(:[]).with(:machine)
      described_class.new(app, env, condition).call(env)
    end

    it "should fire trigger when all conditions are satisfied" do
      Vagrant::Util::Subprocess.should_receive(:execute).with("foo")
      described_class.new(app, env, condition).call(env)
    end

    it "should fire all defined triggers" do
      @triggers << { :action => machine_action, :condition => condition, :options => { :execute => "bar" } }
      Vagrant::Util::Subprocess.should_receive(:execute).twice
      described_class.new(app, env, condition).call(env)
    end

    it "shouldn't execute trigger with no command" do
      @triggers[0][:options] = {}
      Vagrant::Util::Subprocess.should_not_receive(:execute)
      described_class.new(app, env, condition).call(env)
    end

    it "shouldn't fire trigger when condition doesn't match" do
      @triggers[0][:condition] = "blah"
      Vagrant::Util::Subprocess.should_not_receive(:execute)
      described_class.new(app, env, condition).call(env)
    end

    it "shouldn't fire trigger when action doesn't match" do
      @triggers[0][:action] = "blah"
      Vagrant::Util::Subprocess.should_not_receive(:execute)
      described_class.new(app, env, condition).call(env)
    end

    it "should raise an error if executed command exits with non-zero code" do
      result.stub(:exit_code => 1)
      expect { described_class.new(app, env, condition).call(env) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandFailed)
    end

    it "shouldn't raise an error if executed command exits with non-zero code but :force option was specified" do
      @triggers[0][:options][:force] = true
      result.stub(:exit_code => 1)
      expect { described_class.new(app, env, condition).call(env) }.not_to raise_error()
    end

    it "should display output if :stdout option was specified" do
      @triggers[0][:options][:stdout] = true
      result.stub(:stdout => "Some output")
      ui.should_receive(:info).with("Command output:\n\nSome output\n")
      described_class.new(app, env, condition).call(env)
    end
  end

  context "with a command not in the PATH" do
    before do
      @tmp_dir = Vagrant::Util::Platform.windows? ? ENV["USERPROFILE"] : ENV["HOME"]
      File.open("#{@tmp_dir}/foo", "w+", 0700) { |file| }
      File.stub(:executable? => false)
      File.stub(:executable?).with("#{@tmp_dir}/foo").and_return(true)
    end

    after do
      File.delete("#{@tmp_dir}/foo")
    end

    it "should raise a CommandUnavailable error by default" do
      expect { described_class.new(app, env, condition).call(env) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandUnavailable)
    end

    it "should raise a CommandUnavailable error on Windows" do
      Vagrant::Util::Platform.stub(:windows? => true)
      expect { described_class.new(app, env, condition).call(env) }.to raise_error(VagrantPlugins::Triggers::Errors::CommandUnavailable)
    end

    it "should honor the :append_to_path option and restore original path after execution" do
      @triggers[0][:options][:append_to_path] = @tmp_dir
      original_path = ENV["PATH"]
      described_class.new(app, env, condition).call(env)
      expect(ENV["PATH"]).to eq(original_path)
    end

    it "should accept an array for the :append_to_path option" do
      @triggers[0][:options][:append_to_path] = [@tmp_dir, @tmp_dir]
      expect { described_class.new(app, env, condition).call(env) }.not_to raise_error()
    end
  end
end
