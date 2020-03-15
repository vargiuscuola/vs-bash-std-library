# std-lib.bash

<p align="left">
  <a href="https://github.com/vargiuscuola/std-lib.bash"><img alt="vs-bash-std-library Actions Status" src="https://github.com/vargiuscuola/vs-bash-std-library/workflows/CI%20Workflow/badge.svg"></a>
</p>

**These libraries are incomplete and still not intended for use**

Some bash libraries to manage and manipulate traps, locks, arguments, arrays, hashes, strings and others.
Functions are organized in the following modules:
* package.sh  
  Install a package of shell libraries contained in a git repository
* module.sh  
  Load a shell library module, i.e. a set of homogeneous functions
* main.sh  
  Generic functions for manipulating arrays, hashes, strings, coloured messages and more
* trap.sh  
  Provide support for managing hooks functions to signals and debugger trace functionalities
* args.sh  
  A parser of command line options and arguments


# Installation

Clone the repository:
```console
git clone git@github.com:vargiuscuola/std-lib.bash.git /lib/sh/std-lib.bash
```

and load the required modules from your script:
```bash
source "/lib/sh/std-lib.bash/module.sh"
module.import "std-lib.bash/main"
module.import "std-lib.bash/trap"
```

# Reference

**Documentation is still incomplete and in progress**

* [main.sh](REFERENCE-main.md)
* [package.sh](REFERENCE-package.md)
* [module.sh](REFERENCE-module.md)
* [trap.sh](REFERENCE-trap.md)
* [args.sh](REFERENCE-args.md)



