require "spec_helper"

describe VagrantPlugins::Triggers::Config::Trigger do
  let(:config)  { described_class.new }
  let(:machine) { double("machine") }

  describe "defaults" do
    subject do
      config.tap do |o|
        o.finalize!
      end
      expect(config.triggers).to eq([])
    end
  end

  describe "add triggers" do
    it "should add before triggers" do
      config.before(:up) { run "ls" }
      expect(config.triggers.size).to eq(1)
    end

    it "should add instead_of triggers" do
      config.instead_of(:up) { run "ls" }
      expect(config.triggers.size).to eq(1)
    end

    it "should add after triggers" do
      config.after(:up) { run "ls" }
      expect(config.triggers.size).to eq(1)
    end
  end

  describe "blacklist" do
    it "should blacklist an action" do
      config.blacklist(:up)
      expect(config.blacklist.size).to eq(1)
    end

    it "should blacklist multiple actions" do
      config.blacklist([:up, :destroy])
      expect(config.blacklist.size).to eq(2)
    end

    it "should convert symbols to strings" do
      config.blacklist(:up)
      expect(config.blacklist).to eq(["up"])
    end

    it "should blacklist an action only once" do
      config.blacklist(["up", "destroy"])
      config.blacklist(:up)
      expect(config.blacklist).to eq(["up", "destroy"])
    end
  end

  describe "accept multiple entries" do
    it "should record multiple entries" do
      config.before(:up) { run "ls" }
      config.after(:up) { run "ls" }
      expect(config.triggers.size).to eq(2)
    end

    it "should record multiple entries if the action is an array" do
      config.before([:up, :halt]) { run "ls" }
      expect(config.triggers.size).to eq(2)
    end
  end

  describe "validation" do
    it "should validate" do
      config.finalize!
      expect(config.validate(machine)["triggers"].size).to eq(0)
    end

    it "shouldn't accept invalid methods" do
      config.foo "bar"
      expect(config.validate(machine)["triggers"].size).to eq(1)
    end
  end
end
