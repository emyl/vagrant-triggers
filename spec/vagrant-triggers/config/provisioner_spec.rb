require "spec_helper"

describe VagrantPlugins::Triggers::Config::Provisioner do
  let(:config)  { described_class.new }

  describe "fire" do
    it "should record trigger code" do
      code = Proc.new { "foo" }
      config.fire(&code)
      expect(config.trigger_body).to eq(code)
    end
  end

  describe "set_options" do
    it "should set options" do
      options = { :foo => "bar", :baz => "bat" }
      config.set_options(options)
      expect(config.options).to eq(options)
    end
  end
end
