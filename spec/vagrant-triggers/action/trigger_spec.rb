require "spec_helper"

describe VagrantPlugins::Triggers::Action::Trigger do
  let(:app)            { lambda { |env| } }
  let(:env)            { { :action_name => action_name, :machine => machine, :machine_action => machine_action, :ui => ui } }
  let(:condition)      { double("condition") }
  let(:action_name)    { double("action_name") }
  let(:machine)        { double("machine", :ui => ui) }
  let(:machine_action) { double("machine_action") }

  let(:ui)             { double("ui", :info => info) }
  let(:info)           { double("info") }

  before :each do
    trigger_block = Proc.new { nil }
    @triggers     = [ { :action => machine_action, :condition => condition, :options => { }, :proc => trigger_block } ]
    machine.stub(:name)
    machine.stub_chain(:config, :trigger, :blacklist).and_return([])
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
    VagrantPlugins::Triggers::DSL.stub(:new).with(machine, @triggers.first[:options]).and_return(dsl)
    dsl.should_receive(:instance_eval).and_yield
    described_class.new(app, env, condition).call(env)
  end

  it "should fire trigger when condition matches and action is :ALL" do
    @triggers[0][:action] = :ALL
    dsl = double("dsl")
    VagrantPlugins::Triggers::DSL.stub(:new).with(machine, @triggers.first[:options]).and_return(dsl)
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
    dsl = double("dsl")
    dsl.should_not_receive(:instance_eval)
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't fire trigger when the action is blacklisted" do
    machine.stub_chain(:config, :trigger, :blacklist).and_return([machine_action])
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't fire trigger when condition doesn't match" do
    @triggers[0][:condition] = :blah
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't fire trigger when action doesn't match" do
    @triggers[0][:action] = :blah
    VagrantPlugins::Triggers::DSL.should_not_receive(:new)
    described_class.new(app, env, condition).call(env)
  end

  it "shouldn't carry on in the middleware chain on instead_of condition" do
    @triggers[0][:condition] = :instead_of
    app.should_not_receive(:call).with(env)
    described_class.new(app, env, :instead_of).call(env)
  end

  it "should handle gracefully a not matching :vm option" do
    VagrantPlugins::Triggers::DSL.stub(:new).and_raise(VagrantPlugins::Triggers::Errors::NotMatchingMachine)
    expect { described_class.new(app, env, condition).call(env) }.not_to raise_exception()
  end
end
