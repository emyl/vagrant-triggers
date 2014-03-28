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

  before do
    trigger_block = Proc.new { nil }
    @triggers     = [ { :action => machine_action, :condition => condition, :options => { }, :proc => trigger_block } ]
    machine.stub_chain(:config, :trigger, :deprecation_warning)
    machine.stub_chain(:config, :trigger, :triggers).and_return(@triggers)
  end

  it "should skip :environment_load and :environment_unload actions" do
    [:environment_load, :environment_unload].each do |action|
      env.stub(:[]).with(:action_name).and_return(action)
      VagrantPlugins::Triggers::DSL.should_not_receive(:new)
      described_class.new(app, env, condition).call(env)
    end
  end

  it "shouldn't fire if machine action is not defined" do
    env.stub(:[]).with(:action_name)
    env.stub(:[]).with(:machine_action).and_return(nil)
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "should fire trigger when all conditions are satisfied" do
    dsl = double("dsl")
    VagrantPlugins::Triggers::DSL.stub(:new).with(ui, @triggers.first[:options]).and_return(dsl)
    dsl.should_receive(:instance_eval).and_yield
    described_class.new(app, env, condition).call(env)
  end

  it "should fire all defined triggers" do
    @triggers << @triggers.first
    VagrantPlugins::Triggers::DSL.should_receive(:new).twice
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't execute trigger with no command or block" do
    @triggers[0][:proc] = nil
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't fire trigger when condition doesn't match" do
    @triggers[0][:condition] = "blah"
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't fire trigger when action doesn't match" do
    @triggers[0][:action] = "blah"
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "should emit a warning message if the deprecation warning flag is set" do
    machine.stub_chain(:config, :trigger, :deprecation_warning).and_return(true)
    ui.should_receive(:warn).with(/DEPRECATION WARNING/)
    described_class.new(app, env, condition).call(env)
  end
end
