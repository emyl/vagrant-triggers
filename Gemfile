source 'https://rubygems.org'

gemspec

# Warning: Hack below.
#
# Add the current project gem to the "plugins" group
dependencies.find { |dep| dep.name == "vagrant-triggers" }.instance_variable_set(:@groups, [:default, :plugins])

group :development do
  gem "vagrant", :github => "mitchellh/vagrant", :ref => ENV.fetch("VAGRANT_VERSION", "master")
end

group :test do
  gem "simplecov", :require => false
end
