describe "Vagrant" do
  it "can run vagrant with the plugin loaded" do
    env = Vagrant::Environment.new
    expect(env.cli("-h")).to eq(0)
  end
end
