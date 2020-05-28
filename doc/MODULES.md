# Gaudi modules

The modules concept allows us to add code to gaudi installations from multiple sources and have it be required and integrated in the way that gaudi core expects.

A "gaudi module" has a fixed directory structure:

* helpers - a directory for library code. All .rb files here are automatically required during the configuration process
* tasks - a directory for rake tasks. All files here are automatically required after gaudi is configured. All helpers are guaranteed to already be required at this stage.

## Using modules

* Create a directory under tools/build/lib and name it after your module.
* Place files in the appropriate subfolders.
* Add the module to the system configuration

In the system configuration file add the following:

```text
gaudi_modules= my_module
```

This instructs gaudi to look in lib/my_module and incorporate the helpers and tasks it finds.

## Managing modules

The gaudi gem offers a way to download/update modules from git repositories.

The git repository needs to mirror the structure of gaudi core (a lib/module_name directory)

```bash
gaudi -l foo https://module.source/foo.git my_project
```

So you can keep your super-extra-reusable-generic-code in a separate repository and share between projects.
