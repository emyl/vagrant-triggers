source 'https://rubygems.org'

gemspec

group :development do
  gem "vagrant", :github => "mitchellh/vagrant", :ref => ENV.fetch("VAGRANT_VERSION", "v1.4.3")
end

group :test do
  gem "simplecov", :require => false
end
