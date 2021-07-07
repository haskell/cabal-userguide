# What is a module and a package?

## What is a module

At its most basic, a module is a namespace for collecting types, functions, and
typeclasses. Modules are a common feature in most languages, and the ML family
of languages in particular are known for having a very robust module system
(OCaml has full blown ML modules, and haskell has partial support for them with
[backpack](../getting_fancy/10_backpack.md)). Haskell modules are very
feature-full, they can export all or some of their entities, and imports can be
qualified with a namespace, explicitly import a few entities, or even hide
specific entities. However, unlike ML modules, Haskell modules are not first
class.

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

Modules can be used to separate concerns, and split up chunks of code into
logical and manageable pieces.

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
> you can move relatively static code down the dependency graph.

A crucial point to understand here is that `GHC` is responsible for this
recompilation logic. Why, as cabal users, is it important that we understand the
module dependency graph and what modules can do for us? The answer is two-fold:

1. We will often interface with GHC's recompilation functionality through
   `cabal` with commands like `cabal build` and `cabal repl`.
2. The module is the smallest unit of concern within cabal, and therefore it is
   worthwhile to understand its meaning, use cases, and impact on our codebase.

## What is a module to Cabal?

As a user of cabal we are trying to accomplish a couple of things, we are trying
to manage the code that we depend on, and we are trying to package the code that
we have written. Hopefully the previous section gave a bit of insight into
managing code dependencies internally (i.e. the code that we have written), but
how do we package these modules?

Cabal needs to be aware of all the modules that we would like to expose
externally. Now _what_ we choose to expose is up to us. Sometimes we just want
to write an application, in which case we don't need to expose any modules, just
the `main` entrypoint that gets called when we run our executable. Sometimes we
want to write a library for others to use, and we want to liberally expose
everything. Sometimes we want to write a library with some nasty internal
machinery which we would prefer to keep internal, and only expose the clean
external api. All of these use cases can be expressed in cabal, but they require
us to tell cabal exactly what we want to do.

## What is a package
