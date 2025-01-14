# gaudi Changelog

## 1.1.2

* The last Windows remnant: Fixed a bug in the rdoc generation where a capital letter was used in the path

## 1.1.1

* Fixed a bug in determining the namespace when generating the graph

## 1.1.0

* Added task to create a graph of all available tasks as documentation (with colors)
* Using [ColorBrewer Set 1 of 9-class](http://colorbrewer2.org/#type=qualitative&scheme=Set1&n=9) for colours. Unfortunately no color-blind safe option for 9 classes available

## 1.0.0

* Major restructure.
* Split the C/C++ build functionality off to a separate module. Gaudi core is now just the configuration loader and the build system placement conventions
* Added task timing information to the core by monkey patching task invocation in rake.
* Dropped support for Ruby 2.0 and 2.1, add 2.4 to the CI
* Dropped automatic inclusion of custom module.
* Dropped custom module altogether, folded functionality into gaudi-c

## 0.12.1

* Build configuration keys defined as lists (e.g. deps etc.) are now appendable (thanks to [MarkusPalcer](https://github.com/MarkusPalcer))

## 0.12.0

* Auto-generated build rules per target platform (makes running off-the-shelf a little bit easier)
* Modules concept allows us to place code in directories other than custom

## 0.11.0

* Allow multiple source subdirectories per platform configuration
* Allow compiler options specific to the file extension

## 0.10.3

* Bugfix Gaudi::Component#interface now handles multiple header extensions correctly

## 0.10.2

* Actually allow a Component to instantiate with no build.cfg

## 0.10.1

* Minor fix to allow absolute paths with quotes (damn you Windows!)

## 0.10.0

* Allow for missing build.cfg files
* Returned paths are now absolute

## 0.9.2

* Log reduction

## 0.9.1

* Fixed broken Gaudi.configuration

## 0.9.0

* Allow interpolation of values in configuration files with %{value}

## 0.8.1

* Gaudi::Program now looks for sources in a like-named code component

## 0.8.0

* Breadcrumb files for compilation no longer created next to the sources (created next to the output)
* Breadcrumb extension is now .breadcrumb in the generic case (.link and .library are still used)

## 0.7.9

* Expose the name of the deployment in a Gaudi::Program instance
* Bugfix in graph:deployment

## 0.7.8

* Allow quotes in paths within configuration parameters

## 0.7.7

* Component dependencies now include all headers not just the public ones

## 0.7.6

* .s are assembly files
* fixed option setting for assembler to accomodate IAR

## 0.7.5

* Added list:deployments task

## 0.7.4

* Fixed a bug with the assembler breadcrumb extension
* Fixed a bug where source and header extensions were not recognised if there were spaces in the configuration

## 0.7.3

* Fixed a bug in naming object files using a parent component

## 0.7.2

* Removed scaffolding code (new:project task)

## 0.7.1

* Gaudi:Component now has a reference to parent Program or Library if it exists

## 0.7.0

* Platform configuration is now progressively extended by program and component configurations. Solves bugs #1 & #3

## 0.6.0

* Removed command files from the dependency chain.
  * This removes some buggy edge cases and has minimal performance impact. Also makes creating build rules simpler
* switch_configuration and switch_platform_configuration are now in Gaudi::Configuration

## 0.5.0

* Moved artifact naming methods over to custom/paths.rb
* The configuration classes now enumerate all configuration files and respond to configuration_files() returning an Array
* removed config_file from the configuration classes. Use configuration_files.first to get the main file
* Deployments don't allow programs of the same name in the same platform

## 0.4.0

* Binary extensions now part of the platform configuration
* Platform configuration now shared library aware. Archiver renamed to Librarian

## 0.3.0

* Source file extensions now part of the platform configuration
* The directory structure methods are now in custom/helpers/paths.rb

## 0.2.0

* Test coverage is satisfactory
* Path and dependency resolution work reliably
* Configuration system is stable
* Scaffolding code added

## 0.0.1

* Initial version, totally unstable
