# Installing cabal + GHC

## ghcup

While most package managers (notably [chocolatey](https://chocolatey.org/) for
Windows) have some support for installing at least ghc (and sometimes cabal) the
suggested method these days is `ghcup`. You should be able to run the curl
command from [here](https://www.haskell.org/ghcup/) which should install the
ghcup toolchain. Once you have ghcup installed you should be able to run
commands via the tui `ghcup tui` or from the cli:

> Note: these commands are taken directly from the ghcup repo.

```
# list available ghc/cabal versions
ghcup list

# install the recommended GHC version
ghcup install ghc

# install a specific GHC version
ghcup install ghc 8.10.4

# set the currently "active" GHC version
ghcup set ghc 8.8.4

# install cabal-install
ghcup install cabal

# update ghcup itself
ghcup upgrade
```

Once you have `cabal-install` and `ghc` installed you should be able to check
the versions in your terminal:

```
$ cabal --version
cabal-install version 3.2.0.0
compiled using version 3.2.0.0 of the Cabal library
$ ghc --version
The Glorious Glasgow Haskell Compilation System, version 8.8.4
```

You should have version 3 of cabal or later and greater than 8.8 for GHC.
Although the GHC version shouldn't matter too much for this tutorial.

You can test that cabal is working correctly by running the following commands

```
$ mkdir temp
$ cd temp
$ cabal init

Guessing dependencies...

Generating LICENSE...
Warning: unknown license type, you must put a copy in LICENSE yourself.
Generating Setup.hs...
Generating CHANGELOG.md...
Generating Main.hs...
Generating temp.cabal...

Warning: no synopsis given. You should edit the .cabal file and add one.
You may want to edit the .cabal file and add a Description field.

$ ls
CHANGELOG.md  Main.hs  Setup.hs  temp.cabal
```

If everything looks good, then you are ready to proceed to the rest of the
guide!
