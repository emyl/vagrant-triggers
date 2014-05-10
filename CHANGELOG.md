## 0.4.0 (Unreleased)

IMPROVEMENTS:

  - Ensure the `run` statement always returns the command output.

## 0.3.0 (April 4, 2014)

CHANGES:

  - Implement a new DSL for running scripts.

DEPRECATIONS:

  - The ```:info``` and ```:execute``` options has been replaced by the new DSL.

IMPROVEMENTS:

  - Plugin messages are now localized.

BUG FIXES:

  - Avoid loops by adding VAGRANT_NO_TRIGGERS to the subprocess shell.

## 0.2.2 (March 1, 2014)

NEW FEATURES:

  - Add ```:info``` as an alternative to ```:execute```.

BUG FIXES:

  - Remove Vagrant specific environment variables when executing commands [(#5)](https://github.com/emyl/vagrant-triggers/issues/5)

## 0.2.1 (November 19, 2013)

BUG FIXES:

  - Fixed regression in configuration [(#2)](https://github.com/emyl/vagrant-triggers/issues/2)

## 0.2.0 (October 19, 2013)

NEW FEATURES:

  - New option: ```:append_to_path```.

IMPROVEMENTS:

  - Triggers won't run if ```VAGRANT_NO_TRIGGERS``` environment variable is set.
  - Command argument could also be an array.

## 0.1.0 (August 19, 2013)

  - Initial release.
