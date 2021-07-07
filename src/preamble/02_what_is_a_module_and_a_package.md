# What is a module, a component, and a package?

## TL;DR

A **module** is a unit of code defined by GHC and combined by cabal to create a
**component**. A **package** is a cabal project, usually denoted by a
`<project-name>.cabal` file in the root directory. A **component** is either a
library (a re-usable collection of modules), or an executable (an application
that is the combination of one or more modules into a binary executable). A test
suite is also a **component**, however it is slightly different from the others
since it is usually just run on other modules exported by other components
within the package. A **unit** is just a compiled **component**, which has some
implications for GHC, but isn't really of concern to us as users of cabal.
Broadly speaking, the purpose of cabal is to define a package. Creating a
package entails retrieving other packages that your package depends on,
identifying all of the modules for each component within your package, and then
marshalling all of these internal and external dependencies into components.

> Note: there are ongoing efforts to standardize this terminology. You can read
> more about this terminology
> [here](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/units#background),
> it might be interesting since it explains things from GHC's perspective!

## What is a module?

At its most basic, a module is a namespace for collecting types, functions, and
typeclasses (referred to as entities). Modules are a common feature in most
languages, and the ML family of languages in particular are known for having a
very robust
[module system](https://jozefg.bitbucket.io/posts/2017-01-08-modules.html)
(OCaml has full blown ML modules, and Haskell has partial support for them with
[backpack](../getting_fancy/10_backpack.md) but that's a slightly more advanced
topic). Unlike ML modules, Haskell modules are not first class (they cannot be
passed around as values), and in general Haskell modules are bound to a single
file. Despite this, Haskell modules are very feature-full, they can export all
or some of their entities, and imports of modules can: be qualified with a
prefix, explicitly describe a few entities to bring into scope, or explicitly
hide a few entities and bring the rest into scope. If you want to learn more
about Haskell modules and their syntax, then the
[haskell2010 report](https://www.haskell.org/onlinereport/haskell2010/haskellch5.html)
is a good place to start.

#### What is the impact of separating into Modules?

Modules can be used as an abstraction layer, by limiting what they export. In
this way one can create opaque types.

```haskell
module Money (
  -- Notice that the constructor of PositiveDollar is not exported below
  PositiveDollar,
  -- PositiveDollar(..), <- this would export the constructors as well
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
fingerprint (A unique identifier, in new versions of GHC it is a hash of the
contents of the file) of the modules it depends on. If you change a module that
is depended upon by other modules, you will need to recompile everything
downstream of your change. This means that very large modules, that are imported
frequently, can trigger massive recompilations.

#### How does Module recompilation work?

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
recompilation logic, and a modules capabilities are defined in the Haskell
language specification. Why, as cabal users, is it important for us to
understand the module dependency graph, and how to use modules in general?

The answer is two-fold:

1. We will often interface with GHC's recompilation functionality through
   `cabal` with commands like `cabal build` and `cabal repl`.
2. The module is the smallest unit of concern within cabal, and therefore it is
   worthwhile to understand its meaning, use cases, and impact on our codebase.

## Components - What does a module mean to cabal?

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

These collections of modules which are aggregated and exposed are mediated by a
construct called a **component**. Components are represented by top level keys
within a `.cabal` file. These are the kinds of components that you can define
`library`, `executable`, and `test-suite`. A **library** exposes several modules
which are intended to be used by other packages, an **executable** produces a
compiled binary that can be executed, a **test suite** is a program that can be
invoked like an executable but it generally just tests code that is internal to
the package.

> Note: each of these components will receive individual treatment later on in
> the guide. If you are interested to take a peek now you can find them here:
> [library](../new_to_cabal/06_first_cabal_library.md),
> [executable](../new_to_cabal/06_first_cabal_executable.md),
> [test-suite](../leveling_up/02_first_cabal_test_suite.md)

Just like components, there are specific keys that enumerate to modules:
`exposed-modules`, `other-modules`, `virtual-modules`, `test-module`, and even
`main-is` which describes the entrypoint module for an executable. These fields
are children of the top level component fields (mentioned above). The names
listed here are used to communicate to cabal which modules belong within the
context of a **component**. It is not necessary to commit these fields to
memory, but it is good to be aware of them. Hopefully when you look at the
layout of a `.cabal` file next, you will see the
`package <- component <- module` hierarchy reflected in the nested fields!

## What is a package?

If a module is the smallest unit of code in cabal, a **package** is the largest
unit, and represents a distributable artefact that provides access to
components. From cabal's perspective a **package** must at least contain one
component, but it can provide many (even multiple of the same kind of
component).

The `.cabal` file represents a single package, and is really just a collection
of metadata about the packages constituent parts. It defines the packages
components and their internal dependencies (list of modules) as well as the
packages external dependencies; usually other packages. External dependencies
reside under the key `build-depends`, but there are also foreign (non-Haskell)
dependencies too which live under `foreign-library`.

To make things more concrete, here is a pseudo-Haskell type representing the
package-component-module hierarchy:

```haskell
data Module = Module { moduleName :: Text, moduleEntities :: [Entities] }

data ComponentType = Executable | Library | TestSuite

data Component =
  Component
    { componentName    :: Text
    , componentType    :: ComponentType
    , componentModules :: [Module]
    }

type Package = [Component]
```

> Note: technically a package can contain no components, but if you try and run
> `cabal build` you will get an error telling you that your package contains no
> components.

## Summary

Cabal is a tool for defining and building Haskell packages. Even if we don't
intend to distribute our project, we can still think of it as an unrealized
package. This is important because, inherent in the definition of a package, are
all of its dependencies. This is a very common use case for cabal; to bring a
bunch of dependencies in to scope so that we can explore them and call them from
our own code (even if we don't intend to do anything with our code). This
exploratory workflow is facilitated by commands like `cabal repl`, and
`cabal env` (which is being worked on currently).

Therefore it is informative to think of cabal as handling several distinct
concerns:

1. Describing the internal dependency structure of a project in terms of modules
   and components.
2. Managing the external dependencies of our project and allowing us to access
   them from within our modules.
3. Managing the building and distribution of our package, which is really just a
   collection of components.

I believe that the reader of this guide will get the most out of it if they
consider which of these functions they are interested in preforming with Cabal.
Hopefully understanding these distinct considerations will reveal some of the
intention behind subsequent sections!
