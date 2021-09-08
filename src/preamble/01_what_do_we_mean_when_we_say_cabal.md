# What do we mean when we say cabal?

Cabal is an umbrella term that can refer to either "cabal the spec" (.cabal
files), "cabal the library" (code that understands .cabal files), or "cabal the
tool" (the cabal-install package which provides the cabal executable).

## tl;dr

1. [.cabal file](#the-cabal-file) This is the file that specifies the content of
   Haskell packages. The types of information that can be provided via the
   bespoke file format are: top level metadata about the package, and build
   specific information (exposed modules, external dependencies, language
   extensions, compiler options) about the components that comprise the package.

2. [The Cabal build system](#the-cabal-library) is a library that is used for
   creating packages and building their contents. This build system is used by
   cabal-install and other package managers, stack for example.

3. [cabal-install](#the-binary-cabal-install-cli-tool) is the command line
   utility to help configure, compile and install Haskell libraries and
   programs.

## The .cabal file

The .cabal file contains information that drives the compilation and building of
Haskell packages. The .cabal file lives at the root directory that contains the
haskell source code corresponding to the package. By convention this file is
named `<project-name>.cabal`. It is a text-based, key-value format, that is
divided into subsections called stanzas.

The package properties describe the package as a whole, such as name, license,
author, dependenices, etc. It also contains optional information about optional
components such as
[library properties](../new_to_cabal/06_first_cabal_library.md),
[executables](../new_to_cabal/07_first_cabal_executable.md),
[test-suite](../leveling_up/02_first_cabal_test-suite.md),
[benchmark](src/leveling_up/03_first_cabal_benchmark.md). These components are
also called stanzas.

One of the purposes of Cabal is to make it easier to build a package with
different Haskell implementations. So it provides abstractions of features
present in different Haskell implementations and wherever possible it is best to
take advantage of these to increase portability. For example one of the pieces
of information an author can put in the package’s .cabal file is what language
extensions the code uses. This is preferable to specifying flags for a specific
compiler as it allows Cabal to pick the right flags for the Haskell
implementation that the user picks. It also allows Cabal to figure out if the
language extension is even supported by the Haskell implementation that the user
picks. Where compiler-specific options are needed, there is an “escape hatch”
available. The developer can specify implementation-specific options and more
generally there is a configuration mechanism to customise many aspects of how a
package is built depending on the Haskell implementation, the operating system,
computer architecture and user-specified configuration flags.

There are various
[Haskell implementations](https://wiki.haskell.org/Implementations), but we have
now pretty much all converged on [GHC](https://www.haskell.org/ghc/) as the
standard Haskell implementation.

## The CABAL library

Cabal stands for Common Architecture for Building Applications and Libraries.
This is the library that provides functionality that allows the information in
the .cabal files to be put to use. The Cabal library contains the code for
parsing .cabal files and operations for building haskell packages. Cabal the
library, by convention, is written with Capitalization case. Cabal can take a
haskell dependency graph (of external and internal modules) and use GHC to build
it.

## The binary cabal-install (cli tool)

The cabal binary or more accurately `cabal-install` is the command-line tool
that provides a user interface for dealing with Haskell packages. cabal-install
makes use of Cabal the library to do its job.

cabal-install is a frontend to Cabal. It makes it possible to build Haskell
projects whose sets of dependencies might conflict with each other within the
confines of a single system. A package's .cabal file provides a constraint on
the version of various libraries (version bounds) that they expect. When
cabal-install is asked to build a project, by default it looks at the
dependencies specified in its .cabal file and uses a dependency solver to figure
out a set of packages and package versions that satisfy it. This set of packages
is drawn from Hackage. The chosen versions of the dependenices will be installed
and indexed in a database in the cabal directory (`~/.cabal`).

Conflicts between dependencies are avoided by indexing the installed packages
according to their version and other relevant configuration options. This allows
different projects to retrieve the dependency versions they need.

stack is also a command-line tool that depends on the Cabal Library, and hence
also consumes the information specified in Cabal Package format found in the
.cabal files.

# References

1. [Cabal hackage page](https://hackage.haskell.org/package/Cabal)
2. [cabal-install hackage page](https://hackage.haskell.org/package/cabal-install)
