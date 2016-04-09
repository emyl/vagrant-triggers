require "spec_helper"

describe VagrantPlugins::Triggers::Config::Provisioner do
  let(:config)  { described_class.new }

  describe "defaults" do
    it "should default :good_exit option to [0]" do
      expect(config.options[:good_exit]).to eq([0])
    end

    it "should default :stderr option to true" do
      expect(config.options[:stderr]).to be true
    end

    it "should default :stdout option to true" do
      expect(config.options[:stdout]).to be true
    end
  end

  describe "fire" do
    it "should record trigger code" do
      code = Proc.new { "foo" }
      config.fire(&code)
      expect(config.trigger_body).to eq(code)
    end
  end

  describe "set_options" do
    it "should set options" do
      options = { :foo => "bar" }
      config.set_options(options)
      expect(config.options[:foo]).to eq("bar")
    end

    it "should override defaults" do
      config.set_options(:stdout => false)
      expect(config.options[:stdout]).to be false
    end
  end
end
