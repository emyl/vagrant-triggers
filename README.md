# vagrant-triggers

[![Build Status](https://travis-ci.org/emyl/vagrant-triggers.png?branch=master)](https://travis-ci.org/emyl/vagrant-triggers)

Allow the definition of arbitrary scripts that will run on the host before and/or after Vagrant commands.

## Installation

Ensure you have downloaded and installed Vagrant 1.2+ from the
[Vagrant downloads page](http://downloads.vagrantup.com/).

Installation is performed in the prescribed manner for Vagrant plugins:

    $ vagrant plugin install vagrant-triggers

## Usage

### Basic usage

```ruby
Vagrant.configure("2") do |config|
  # Your existing Vagrant configuration
  ...

  config.trigger.before :command, :option => "value" do
    run "script"
    ...
  end

  config.trigger.after :command, :option => "value" do
    run "script"
    ...
  end

  config.trigger.instead_of :command, :option => "value" do
    run "script"
    ...
  end
end
```

The ```instead_of``` trigger could also be aliased as ```reject```.

The first argument is the command in which the trigger will be tied. It could be an array (e.g. ```[:up, :resume]```) in case of multiple commands.

### Options

* ```:append_to_path => ["dir", "dir"]```: additional places where looking for scripts. See [this wiki page](https://github.com/emyl/vagrant-triggers/wiki/The-:append_to_path-option) for details.
* ```:force => true```: continue even if one of the scripts fails (exits with non-zero code).
* ```:stdout => true```: display script output.
* ```:vm => ["vm1", /vm[2-3]/]```: fire only for matching virtual machines. Value can be a string, a regexp or an array of strings and/or regexps.

### Trigger block DSL

The given block will be evaluated by an instance of the [VagrantPlugins::Triggers::DSL](https://github.com/emyl/vagrant-triggers/blob/master/lib/vagrant-triggers/dsl.rb) class. This class defines a very simple DSL for running scripts on the host machine. Only a few methods are directly defined, all the other calls will be forwarded to Vagrant's [ui](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/ui.rb) instance. This allows the definition of custom messages along with scripts.

For additional details you can take a look to the [VagrantPlugins::Triggers::DSL](https://github.com/emyl/vagrant-triggers/blob/master/lib/vagrant-triggers/dsl.rb) definition.

### Skipping execution

Triggers won't run if ```VAGRANT_NO_TRIGGERS``` environment variable is set.

## A simple example

Cleanup some temporary files after machine destroy:

```ruby

Vagrant.configure("2") do |config|
  config.trigger.after :destroy do
    run "rm -Rf tmp/*"
  end
end
```

## A more detailed example

In the following example a VirtualBox VM (not managed by Vagrant) will be tied to the machine defined in ```Vagrantfile```, to make so that it follows its lifecycle:

```ruby

Vagrant.configure("2") do |config|

  {
    [:up, :resume] => "startvm 22aed8b3-d246-40d5-8ad4-176c17552c43 --type headless",
    :suspend       => "controlvm 22aed8b3-d246-40d5-8ad4-176c17552c43 savestate",
    :halt          => "controlvm 22aed8b3-d246-40d5-8ad4-176c17552c43 acpipowerbutton",
  }.each do |command, trigger|
    config.trigger.before command, :stdout => true do
      info "Executing #{command} action on the VirtualBox tied VM..."
      run  "vboxmanage #{trigger}"
    end
  end

end
```

For additional examples, see the [trigger recipes](https://github.com/emyl/vagrant-triggers/wiki/Trigger-recipes) wiki page.

## Contributing

To contribute, clone the repository, and use [Bundler](http://bundler.io/)
to install dependencies:

    $ bundle

To run the plugin's tests:

    $ bundle exec rake

You can now fork this repository, make your changes and send a pull request.
