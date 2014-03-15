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

The following ```Vagrantfile``` configuration options are added:

```
trigger.before :command, { :option => "value", ... }
```

```
trigger.after :command, { :option => "value", ... }
```

The first argument is the command in which the trigger will be tied. It could be an array (e.g. ```[:up, :resume]```) in case of multiple commands.

### Options

* ```:execute => "script"```: the script to execute
* ```:call => proc```: a Proc object. When called, Vagrant's env object will be passed to the proc/block as the first argument.
                       This option also takes precedence over :execute if specified.
                       Alternatively, this option can also be passed as a block, which will overwrite this option, to the trigger.
* ```:info => "string"```: an informational message to be displayed, instead of executing a command. This is only displayed if :execute is not set.

* ```:append_to_path => ["dir", "dir"]```: additional places where looking for the script. See [this wiki page](https://github.com/emyl/vagrant-triggers/wiki/The-:append_to_path-option) for details.
* ```:force => true```: continue even if the script fails (exits with non-zero code)
* ```:stdout => true```: display script output

### Skipping execution

Triggers won't run if ```VAGRANT_NO_TRIGGERS``` environment variable is set.

## Example

In the following example a VirtualBox VM (not managed by Vagrant) will be tied to the machine defined in ```Vagrantfile```, to make so that it follows its lifecycle:

```ruby

Vagrant.configure("2") do |config|

  {
    [:up, :resume] => "startvm 22aed8b3-d246-40d5-8ad4-176c17552c43 --type headless",
    :suspend       => "controlvm 22aed8b3-d246-40d5-8ad4-176c17552c43 savestate",
    :halt          => "controlvm 22aed8b3-d246-40d5-8ad4-176c17552c43 acpipowerbutton",
  }.each do |command, trigger|
    config.trigger.before command, :execute => "vboxmanage #{trigger}", :stdout => true
  end

end
```


```ruby

Vagrant.configure("2") do |config|

  config.trigger.before :up do |env|
    yn = env[:ui].ask("Would you like to recreate DB volume? [y/N] ")
    # ... do something about the answer ...
  end
end
```

## Contributing

To contribute, clone the repository, and use [Bundler](http://bundler.io/)
to install dependencies:

    $ bundle

To run the plugin's tests:

    $ bundle exec rake

You can now fork this repository, make your changes and send a pull request.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/emyl/vagrant-triggers/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

