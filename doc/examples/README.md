#Gaudi Examples

The examples follow the naming and directory structure conventions described in [CONVENTIONS.md](CONVENTIONS.md)

In each example only the relevant directories and files are present.

## Examples
 * Adding [unit tests using Unity & CMock](unit_testing/README.md)

## Windows?

The examples make some assumptions on the underlying OS. When a choice is required, then Windows is chosen. The reason is that Gaudi is targeted mostly at embedded development and cross-compilers from the majority of CPU manufacturers even now in 2014 run on Windows. Some run only on Windows. The situation is getting better but you can't discard Windows and it does present the most difficult environment to work on.

Gaudi is 100% pure Ruby. C extensions have been avoided on purpose, development is done on OS X and it has been used in Linux environments. Windows, because embedded CPU manufacturers.
