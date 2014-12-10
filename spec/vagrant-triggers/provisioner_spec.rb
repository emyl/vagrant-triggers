require "spec_helper"

describe VagrantPlugins::Triggers::Provisioner do
  let(:config)  { double("config", :options => options, :trigger_body => Proc.new { "foo" }) }
  let(:machine) { double("machine") }
  let(:options) { double("options") }

  before :each do
    ENV["VAGRANT_NO_TRIGGERS"] = nil
  end

  describe "constructor" do
    it "should create a DSL object" do
      VagrantPlugins::Triggers::DSL.should_receive(:new).with(machine, options)
      described_class.new(machine, config)
    end

    it "should handle gracefully a not matching :vm option" do
      VagrantPlugins::Triggers::DSL.stub(:new).and_raise(VagrantPlugins::Triggers::Errors::NotMatchingMachine)
      expect { described_class.new(machine, config) }.not_to raise_exception()
    end
  end

  describe "provision" do
    before :each do
      @dsl = double("dsl")
      VagrantPlugins::Triggers::DSL.stub(:new).with(machine, options).and_return(@dsl)
    end

    it "should run code against DSL object" do
      @dsl.should_receive(:instance_eval).and_yield
      described_class.new(machine, config).provision
    end

    it "should not run code if VAGRANT_NO_TRIGGERS is set" do
      ENV["VAGRANT_NO_TRIGGERS"] = "1"
      @dsl.should_not_receive(:instance_eval)
      described_class.new(machine, config).provision
    end
  end
end
