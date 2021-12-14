# gaudi Modules

The concept of gaudi modules allows to add code to gaudi installations from
multiple sources and to have it being required and integrated in the way that
gaudi core expects.

A "gaudi module" has a fixed directory structure:

* `helpers` - a directory for library code. All `.rb` files in there are
  automatically required during the configuration loading process
* `tasks` - a directory for rake tasks. All files here are automatically
  required after gaudi is configured. All helpers are guaranteed to already be
  required at this stage.

## Utiliztation Of Modules In A gaudi Managed Build System

* A directory named after the new module is to be created under
  `tools/build/lib`
* Ruby files declaring new tasks and their helpers are to be placed into the
  appropriate subfolders of the new module
* Lastly the new module has to be added to the system configuration

The new module has to be added to the `gaudi_modules` variable within the system
configuration as follows:

```text
gaudi_modules=some_c_module,a_csharp_module,ci_module,the_newly_added_module
```

This instructs gaudi to look in `lib/the_newly_added_module` directory and
incorporate the helpers and tasks it finds within it.

## Managing Modules

The gaudi gem offers a way to download/update modules from git repositories.

The git repository needs to mirror the structure of gaudi core (a
`lib/module_name` directory). It then can be added to an existing project as
follows:

```bash
gaudi -l foo https://module.source/foo.git my_project
```

So reusable generic code can be kept in a separate repository and be shared
between projects.
