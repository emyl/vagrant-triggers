# vagrant-triggers

[![Build Status](https://travis-ci.org/emyl/vagrant-triggers.png?branch=master)](https://travis-ci.org/emyl/vagrant-triggers)

Allow the definition of arbitrary scripts that will run on the host or guest before and/or after Vagrant commands.

## Installation

Ensure you have downloaded and installed Vagrant 1.2+ from the
[Vagrant downloads page](http://downloads.vagrantup.com/).

Installation is performed in the prescribed manner for Vagrant plugins:

    $ vagrant plugin install vagrant-triggers

## Example Usage

```ruby
Vagrant.configure("2") do |config|
  # Your existing Vagrant configuration
  ...

  # run some script before the guest is destroyed
  config.trigger.after :destroy do
    info "Dumping the database before destroying the VM..."
    run_remote  "bash /vagrant/cleanup.sh"
  end


  # clean up files on the host after the guest is destroyed
  config.trigger.after :destroy do
    run "rm -Rf tmp/*"
  end

  # start apache on the guest after the guest starts
  config.trigger.after :up do
    run_remote "service apache2 start"
  end

end
```


## Syntax Overview

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

Starting from version 0.5.0, triggers can also be run as a provisioner:

```ruby
Vagrant.configure("2") do |config|
  # Your existing Vagrant configuration
  ...

  config.vm.provision "trigger", :option => "value" do |trigger|
    trigger.fire do
      run "script"
    end
  end
end
```

### Options

* ```:append_to_path => ["dir", "dir"]```: additional places where looking for scripts. See [this wiki page](https://github.com/emyl/vagrant-triggers/wiki/The-:append_to_path-option) for details.
* ```:force => true|false```: continue even if one of the scripts fails (exits with non-zero code). Defaults to false.
* ```:stderr => true|false```: display standard error from scripts. Defaults to true.
* ```:stdout => true|false```: display standard output from scripts. Defaults to true.
* ```:vm => ["vm1", /vm[2-3]/]```: fire only for matching virtual machines. Value can be a string, a regexp or an array of strings and/or regexps.

### Trigger block DSL

The given block will be evaluated by an instance of the [VagrantPlugins::Triggers::DSL](https://github.com/emyl/vagrant-triggers/blob/master/lib/vagrant-triggers/dsl.rb) class. This class defines a very simple DSL for running scripts on the host machine. Only a few methods are directly defined, all the other calls will be forwarded to Vagrant's [ui](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/ui.rb) instance. This allows the definition of custom messages along with scripts.

For additional details you can take a look to the [VagrantPlugins::Triggers::DSL](https://github.com/emyl/vagrant-triggers/blob/master/lib/vagrant-triggers/dsl.rb) definition.

### Skipping execution

Triggers won't run if ```VAGRANT_NO_TRIGGERS``` environment variable is set.

### Attaching to every command

The special name `:ALL` can be used as a wildcard for every vagrant command:

```ruby
Vagrant.configure("2") do |config|
  config.trigger.before :ALL do
    ...
  end
end
```

### Blacklisting commands

Commands can be blacklisted, so that the `:ALL` wildcard has no effect on them:

```ruby
Vagrant.configure("2") do |config|
  config.trigger.blacklist :destroy
  config.trigger.before :ALL do
    ...
  end
end
```

Multiple commands can be blacklisted using an array.



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
