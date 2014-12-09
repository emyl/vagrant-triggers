require "spec_helper"

describe VagrantPlugins::Triggers::Provisioner do
  let(:config)  { double("config", :options => options, :trigger_body => Proc.new { "foo" }) }
  let(:machine) { double("machine") }
  let(:options) { double("options") }

  describe "constructor" do
    it "should create a DSL object" do
      VagrantPlugins::Triggers::DSL.should_receive(:new).with(machine, options)
      described_class.new(machine, config)
    end
  end

  describe "provision" do
    it "should run code against DSL object" do
      dsl = double("dsl")
      VagrantPlugins::Triggers::DSL.stub(:new).with(machine, options).and_return(dsl)
      dsl.should_receive(:instance_eval).and_yield
      described_class.new(machine, config).provision
    end
  end
end
