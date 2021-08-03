# What do we mean when we say cabal?

Cabal is an umbrella term that can refer to either cabal-the-spec (.cabal
files), cabal-the-library (code that understands .cabal files), or
cabal-the-tool (the cabal-install package which provides the cabal executable).

## tl;dr

1. [cabal-install](#cabalInstall) is the command line utility to help configure,
   compile and install Haskell libraries and programs.

2. [The Cabal build system](#cabailBuildSystem), a specification for defining
   Haskell packages, together with a library for performing builds. This build
   system is used by cabal-install and other package managers (stack for eg).
   For eg: parsing .cabal files (among others).

3. [.cabal file](#cabalFile) This is the format that specifies the content of
   Haskell packages.

## The .cabal file<a name="cabalFile"></a>

The .cabal file contains information that drives the compilation and building of
Haskell packages. This is the format that specifies the content of Haskell
packages. It is a text-based, key-value format, that is divided into subsections
called stanzas. Each section consists of a number of property descriptions in
the form of field/value pairs, with a syntax roughly like mail message headers.
It is denoted with a file with the .cabal extension.

This file should contain a number global property descriptions and several
sections. The package properties describe the package as a whole, such as name,
license, author, etc. Optionally, a number of configuration flags can be
declared. These can be used to enable or disable certain features of a package.
The (optional) library section specifies the library properties and relevant
build information. Following is an arbitrary number of executable sections which
describe an executable program and relevant build information.

## The CABAL library <a name="cabalBuildSystem"></a>

CABAL stands for Common Architecture for Building Applications and Libraries.
This is the library that provides functionality that allows the information in
the .cabal files to be put to use. Without the Cabal library, the Cabal package
format is just that, a text file. The Cabal library contains the implementations
that allow for the parsing and operations based on the content of a .cabal file.
Cabal the library by convention is written with a Capitalization case.

## The binary cabal-install (cli tool)<a name="cabalInstall"></a>

The cabal command line tool helps in working with Cabal packages. It (cabal
lowercase) or more accurately `cabal-install` is the command-line tool that
provides a user interface for dealing with Haskell packages. cabal-install makes
use of Cabal the library to do its job.

cabal-install is a frontends to CABAL. It makes it possible to build Haskell
projects whose sets of dependencies might conflict with each other within the
confines of a single system. When cabal-install is asked to build a project, by
default it looks at the dependencies specified in its .cabal file and uses a
dependency solver to figure out a set of packages and package versions that
satisfy it. This set of package is drawn from all package and all versions from
Hackage as a whole. The chosen versions of the dependenices will be installed
and indexed in a database in the cabal directory.

Version conflicts between dependencies are avoided by indexing the installed
packages according to their version and other relevent configuration options.
This allows different projects to retrieve the dependecy versions they need.

    stack is also a command-line tool that depends on the Cabal Library,
    and hence also consumes the information specified in Cabal Package format
    found in the .cabal files.

# References

1. [CABAL hackage page](https://hackage.haskell.org/package/Cabal)
2. [cabal-install hackage page](https://hackage.haskell.org/package/cabal-install)
