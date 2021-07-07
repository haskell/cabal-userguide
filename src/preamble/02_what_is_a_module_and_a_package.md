# What is a module and a package?

## TL;DR

A **module** is a unit of code defined by GHC and combined by Cabal to create
packages. A **package** is either a library (a re-usable collection of modules),
or an executable (an application that is the combination of one or more modules
into a binary executable). A test suite is kind of like a package, in the sense
that it is specified separately at the top-level of a `<project-name>.cabal`
file, and is built up out of modules. However, it is different in the sense that
it is usually not exposed and distributed. Broadly speaking, the point of Cabal
is to define packages.

## What is a module?

At its most basic, a module is a namespace for collecting types, functions, and
typeclasses (referred to as entities). Modules are a common feature in most
languages, and the ML family of languages in particular are known for having a
very robust module system (OCaml has full blown ML modules, and Haskell has
partial support for them with [backpack](../getting_fancy/10_backpack.md) but
that's a slightly more advanced topic). Unlike ML modules, Haskell modules are
not first class (they cannot be passed around as values). Despite this, Haskell
modules are very feature-full, they can export all or some of their entities,
and imports of modules can: be qualified with a prefix, explicitly describe a
few entities to bring into scope, or explicitly hide a few entities and bring
the rest into scope. If you want to learn more about Haskell modules and their
syntax, then the
[haskell2010 report](https://www.haskell.org/onlinereport/haskell2010/haskellch5.html)
is a good place to start.

The humble module, at its core, is just a namespace, but it provides powerful
practical capabilities.

Modules can be used as an abstraction layer, by limiting what they export. In
this way one can create opaque types.

```haskell
module Money (
  PositiveDollar,
  mkPositiveDollar
) where

newtype PositiveDollar = PositiveDollar { unPositiveDollar :: Int }

mkPositiveDollar :: Int -> Maybe PositiveDollar
mkPositiveDollar n
  | n >= 0 = Just . PositiveDollar $ n
  | otherwise = Nothing
```

> Note: If you want to learn more about opaque types and their use cases this
> [resource](https://www.cs.auckland.ac.nz/references/haskell/haskell-intro-html/modules.html)
> is fantastic

Modules can be used to separate concerns, and split up chunks of code into
logical and manageable pieces; an 80 line file is much more approachable, and
easy to take in at a glance, than a 1000 line file.

Module separation can also impact compile times. Each module keeps track of the
fingerprint (A unique identifier, usually the hash of the contents of the file)
of the modules it depends on. If you change a module that is depended upon by
other modules, you will need to recompile everything downstream of your change.
This means that very large modules, that are imported frequently, can trigger
massive recompilations.

```

                                       Main.hs
                                      /   |   \
                                     /   / \   \
                                    A   B   C   D
                                     \   \ /   /
                                  CustomPrelude.hs

```

> Note: Sometimes haskell projects will define a `CustomPrelude.hs` or
> `Import.hs` module to reduce the boiler plate of importing common modules /
> packages. While this isn't necessarily bad, it is important to understand the
> impact it can have on compilation times!

In the diagram above, we can imagine the dependency graph flowing upwards. That
means that `Main.hs` imports `A`, `B`, `C`, and `D`, and all of the lettered
modules depend on `CustomPrelude.hs`. Any change to the lettered modules will
only require a recompilation of the changed module and `Main.hs`. However, if we
make a change to `CustomPrelude.hs` then every single module needs to be
recompiled.

We could do something like split up `CustomPrelude.hs` into a module that is
depended upon by `A` and `B` and another that is depended upon by `C` and `D`.
This means that changes in `PreludeAB.hs` now only recompile `A` and `B` and the
same for `PreludeCD.hs` and `C` and `D`. In this way we reduce overall compile
times by making it clear to GHC, at the module level, which code depends on
what. GHC will use this information to see what work it has already done that is
still valid, and what needs to be re-computed.

```

                                       Main.hs
                                      /   |   \
                                     /   / \   \
                                    A   B   C   D
                                   /   /     \   \
                              PreludeAB.hs   PreludeCD.hs

```

> Note: Main.hs has to be recompiled every time, regardless, so it does help if
> you can move code that doesn't change frequently down the dependency graph.

For a deeper exposition of module recompilation the
[GHC docs](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/recompilation-avoidance)
are a great resource.

A crucial point to understand here is that `GHC` is responsible for this
recompilation logic, and modules capabilities are defined in the Haskell
language specification. Why, as cabal users, is it important for us to
understand the module dependency graph, and how to use modules in general?

The answer is two-fold:

1. We will often interface with GHC's recompilation functionality through
   `cabal` with commands like `cabal build` and `cabal repl`.
2. The module is the smallest unit of concern within cabal, and therefore it is
   worthwhile to understand its meaning, use cases, and impact on our codebase.

## What is a module to Cabal?

As a user of cabal we are trying to accomplish a couple of things, we are trying
to manage the code that we depend on, and we are trying to package the code that
we have written. Hopefully the previous section gave a bit of insight into
managing code dependencies internally (i.e. the code that we have written), but
how do we package these modules up so that they can be consumed?

Cabal needs to be aware of all the modules that we would like to expose
externally. Now _what_ we choose to expose is up to us. Sometimes we just want
to write an application, in which case we don't need to expose any modules, just
the `main` entrypoint that gets called when we run our executable. Sometimes we
want to write a library for others to use, and we want to liberally expose
everything. Sometimes we want to write a library with some nasty internal
machinery which we would prefer to keep hidden, and only expose the clean
external api. All of these use cases can be expressed in cabal, but they require
us to tell cabal exactly what we want to do.

You don't need to know what these are now, but over the course of this user
guide you will see configuration keys like `exposed-modules`, `other-modules`,
`virtual-modules`, `test-module`, and even `main-is` which describes the
entrypoint module for an executable. This information is used to communicate to
Cabal how to treat each module in the context of a `package`.

Hopefully now its clear why you would want a bunch of different modules, and why
you need to enumerate them for cabal!

## What is a package?

While modules are the smallest unit of code in Cabal, a **package** is the
smallest distributable unit. It is composed of modules, and can take the form of
a **library** or an **executable**. A library makes its modules available for
re-use, while an executable is a single program compiled down to binary that is
meant to be run.

From Cabal's perspective a **package** must at least be one executable or
library, and can include several libraries and executables. A package can also
be thought of as including its tests, although a packages tests are not made
available to consumers in the same way that a library and executable are.

A package is defined in the `.cabal` file, which is a collection of metadata
about the package. In addition to metadata, the `.cabal` defines the packages
internal dependency structure (the module graph) as well as its external
dependencies; the other packages that this package depends on.

## Summary

Cabal is a tool for defining and building Haskell packages. Even if we don't
intend to distribute our project, we can still think of it as an unrealized
package. This is important because, inherent in the definition of a package, are
all of its dependencies. This is a very common use case for cabal; to bring a
bunch of dependencies in to scope so that we can explore them and call them from
our own practice projects. This exploratory workflow is facilitated by commands
like `cabal repl`, and `cabal env` (which is being worked on currently).

Therefore it is informative to think of Cabal as handling several distinct
concerns:

1. Describing the internal dependency structure of a project in terms of
   modules.
2. Managing the external dependencies (packages) of our project and bringing
   them into scope so that we can access their exposed modules.
3. Managing the building and distribution of our package.

I believe that the reader of this guide will get the most out of it if they
consider which of these functions they are interested in preforming with Cabal.
Hopefully understanding these distinct considerations will reveal some of the
intention behind subsequent sections!
