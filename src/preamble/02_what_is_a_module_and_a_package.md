# What is a module, a component, and a package?

## TL;DR

There is an ongoing initiative to standardize the terminology we use to refer to
the hierarchy of collections of code in the Haskell community. If you are
interested in reading more about the you can find a more thorough treatment
[here](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/units#background).

The most significant concepts in this chapter all refer to ways of dividing and
aggregating code. They form a hierarchy, and are somewhat defined in terms of
each other. Here is a list of them in order from smallest to largest are:

1. **Module** - The smallest unit of code defined by GHC and the Haskell
   language specification.
2. **Component** - A component is a collection of modules. Usually a `library`,
   `executable`, or a `test-suite`.
3. **Unit** - Units are compiled components, while not technically _larger_ than
   a component, they are further along in the packaging process and therefore
   closer to a distributable artefact.
4. **Package** - A package is a collection of components. In the context of
   cabal a package is identified by a `<package-name>.cabal` file. A package is
   **the** unit of distribution in the Haskell ecosystem i.e. everything on
   hackage is a package.
5. **Project** - A project is a grouping of several related packages. In the
   context of cabal this is denoted by a `cabal.project` file in the root
   directory.

Units and projects are not covered in this chapter, although projects have their
own [chapter](../getting_fancy/01_setting_up_a_cabal_project.md)

## What is a module?

> This section takes inspiration from the introduction to a paper on the formal
> specification of the Haskell module system. While the paper goes into the deep
> end of things fairly quickly the introduction is approachable. I encourage you
> to give it a look
> [here](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.113.4699&rep=rep1&type=pdf)

Modules are a common feature in most programming languages, and tend to serve
three purposes:

- Namespace
- Abstraction
- Separate Compilation

Haskell modules are very feature-full, here are some examples of how they can be
used.

They can export all of their entities.

```haskell
module ExportAll where

id :: a -> a
id a = a

compose :: (b -> c) -> (a -> b) -> (a -> c)
compose f g = \a -> f (g a)
```

They can export a subset of entities.

```haskell
module Identity (
  Identity(..),
  id
) where

data Identity a = Identity a

id :: a -> a
id a = a

compose :: (b -> c) -> (a -> b) -> (a -> c)
compose f g = \a -> f (g a)
```

They can also explicitly export all of their entities.

```haskell
module Composition (
  compose
) where

compose :: (b -> c) -> (a -> b) -> (a -> c)
compose f g = \a -> f (g a)
```

Imports of modules can be qualified with a prefix.

```haskell
import qualified Identity
import qualified Composition as C

identity :: a -> a
identity = C.compose Identity.id Identity.id
```

Imports can explicitly describe a few entities to bring into scope.

```haskell
import Identity (id)
import Composition (compose)

identity :: a -> a
identity = compose id id
```

Imports can explicitly hide a few entities and bring the rest into scope.

```haskell
import ExportAll hiding (compose)
import Composition (compose)

identity :: a -> a
identity = compose id id
```

If you want to learn more about Haskell modules and their syntax, then the
[haskell2010 report](https://www.haskell.org/onlinereport/haskell2010/haskellch5.html)
is a good place to start.

Alright, back to the three primary features of a module, lets look at they
manifest in Haskell.

#### Namespace

At its most basic, a module is a namespace for collecting language specific
primitives. In Haskell these are types, functions, and typeclasses (referred to
as entities). This is by far the most common use case in a Haskell application.
Note namespaces are intended to prevent the collision of homophonous entities,
but are often used to create semantic divisions in the structure of code that
corresponds to some domain specific concept.

It is good practice to make heavy use of namespaces; an 80 line file is much
more approachable, and easy to take in at a glance, than a 1000 line file.

#### Abstraction

First off, what is an abstraction? It is effectively a separation of the
external API from the internal implementation. One can accomplish this with
modules by exporting a subset of entities, thus making the external API smaller
and hiding some of the internals.

The ML family of languages (of which Haskell is a descendant) in particular are
known for having a very robust
[module system](https://jozefg.bitbucket.io/posts/2017-01-08-modules.html), one
which is very good at creating expressive abstractions. While Haskell is related
to the ML family it does not have support for ML style modules, OCaml is an
example of a modern language that does have full blown ML modules. There is an
attempt at adding partial support for ML modules to Haskell, the project is
called [backpack](../getting_fancy/10_backpack.md) but that's a slightly more
advanced topic.

Unlike ML modules, Haskell modules are not first class, they cannot be passed
around as values; Haskell modules are bound to a single file. They can however,
still provide a level of abstraction by limiting exports and creating opaque
types.

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

Now a consumer of the `Money` module can only construct a `PositiveDollar` by
calling `mkPositiveDollar`, which makes the possible values of `Int` smaller
(i.e. none less than 0). The handling of negatives has been abstracted away from
the end user!

#### Separate Compilation

Module separation can also impact compile times. Each module keeps track of the
fingerprint (A unique identifier, in new versions of GHC it is a hash of the
contents of the file) of the modules it depends on. If you change a module that
is depended upon by other modules, you will need to recompile everything
downstream of your change. This means that very large modules, that are imported
frequently, can trigger massive recompilations.

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

## What is a Component?

If modules are the construct that allow us to manage the internal dependencies
of our project, then components are the first glimpse of the external.
Components aggregate all of our internal dependencies to be exposed external,
and components also declare all of the external packages that we depend on so
that they can be made available as modules within our code.

When arranging components Cabal needs to be aware of all the modules that we
would like to expose externally. Now _what_ we choose to expose is up to us.
Sometimes we just want to write an application, in which case we don't need to
expose any modules, just the `main` entrypoint that gets called when we run our
executable. Sometimes we want to write a library for others to use, and we want
to liberally expose everything. Sometimes we want to write a library with some
nasty internal machinery which we would prefer to keep hidden, and only expose
the clean external api. All of these use cases can be expressed using
components.

Components are represented by top level keys within a `.cabal` file. These are
the kinds of components that you can define `library`, `executable`, and
`test-suite`. A **library** exposes several modules which are intended to be
used by other packages, an **executable** produces a compiled binary that can be
executed, a **test suite** is a program that can be invoked like an executable
but it generally just tests code that is internal to the package.

> Note: each of these components will receive individual treatment later on in
> the guide. If you are interested to take a peek now you can find them here:
> [library](../new_to_cabal/06_first_cabal_library.md),
> [executable](../new_to_cabal/06_first_cabal_executable.md),
> [test-suite](../leveling_up/02_first_cabal_test_suite.md)

There are specific keys that we use to enumerate modules within components:
`exposed-modules`, `other-modules`, `virtual-modules`, `test-module`, and even
`main-is` which describes the entrypoint module for an executable. These fields
are children of the top level component fields (mentioned above).

External dependencies are declared at the component level, and reside under the
key `build-depends` (a child of the various component fields). There are also
foreign (non-Haskell) dependencies too which live under `foreign-library`, these
are a bit anomalous in the sense that they are not associated with a single
component, there is a separate
[chapter](../getting_fancy/06_foreign_libraries.md) on them.

It is not necessary to commit these fields to memory, but it is good to be aware
of them. Hopefully when you look at the layout of a `.cabal` file next, you will
see the `package <- component <- module` hierarchy reflected in the nested
fields!

## What is a package?

If a module is the smallest unit of code in cabal, a **package** is the largest
unit of distribution. At its core, all a package is is a distributable artefact
that provides access to components.

> You might remember cabal projects from earlier, as being _upstream_ of
> packages. Good catch, a **project** is bigger in the sense that it is a
> grouping of packages, but it is not distinct in terms of the distribution of
> code.

The `.cabal` file represents a single package, and is really just a collection
of metadata about the packages constituent parts. It defines the packages
components and their internal dependencies (list of modules) as well as the
packages external dependencies; usually other packages.

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
intend to distribute our code, we can still think of it as an unrealized
package. This is important because, inherent in the definition of a package, are
all of its dependencies. This is a very common use case for cabal; to bring a
bunch of dependencies in to scope so that we can explore them and call them from
our own code (even if we don't intend to do anything with our code). This
exploratory workflow is facilitated by commands like `cabal repl`, and
`cabal env` (which is being worked on currently).

Therefore it is informative to think of cabal as handling several distinct
concerns:

1. Describing the internal dependency structure of a package in terms of
   modules.
2. Managing the external dependencies of our project and allowing us to access
   them from within our modules.
3. Managing the building and distribution of our package, which is really just a
   collection of components.

I believe that the reader of this guide will get the most out of it if they
consider which of these functions they are interested in performing with Cabal.
Hopefully understanding these distinct considerations will reveal some of the
intention behind subsequent sections!
