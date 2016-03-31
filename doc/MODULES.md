#Gaudi modules

The modules concept allows us to add code to gaudi installations from multiple sources and have it be required and integrated in the way that gaudi core expects.

A "module" is a copy of the 'custom' directory structure:

* helpers - a directory for library code. All .rb files here are automatically required during the configuration process
* rules - rake rules. All .rb files here are automatically required during the configuration process and after the module's helpers.
* tasks - a directory for rake tasks. All files here are automatically required after gaudi is configured. All helpers are guaranteed to be available at this stage.

##Using modules

* Create a directory under tools/build/lib and name it after your module.
* Place files in the appropriate subfolders.
* Work

##Managing modules

The gaudi gem offers a way to download/update modules from git repositories.

The git repository needs to mirror the structure of gaudi core (a lib/module_name directory)

```
gaudi -l foo https://module.source/foo.git my_project
```

So you can keep your supre-extra-reusable-generic-code in a separate repository and share between projects.

##What about 'custom' and path conventions?

The modules concept exists since v0.12.0.

'custom' is just another module, but it is always included in the list for backward compatibility reasons.

It's also a good way to provide an example and separate the project specific path conventions from core. You can omit 'custom' and place paths.rb in your own module.
