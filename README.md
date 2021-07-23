# TestFunctionRunner

A rather hacky solution to define tests in a package.  In particular, this
package takes care of some ugly details for dealing with:

* doctest (or any `eval`-based testing)
* tests that require loading test code for Distributed.jl

This package is aiming at a clear separation of test *definition* and test
*execution* phases.

## Usage

To create a `Pkg.test`-compatible test entry point `test/runtests.jl`:

1. Create a package at `test/$TestPackageName/` (i.e., there are
   `test/$TestPackageName/Project.toml` and
   `test/$TestPackageName/src/$TestPackageName.jl`).
2. Write tests as functions that takes no argument and the name starting with
   `test_`.  Use `Test.@test` etc. as usual to assert the result.
3. Create `test/runtests.jl` with the following code:

   ```julia
   using TestFunctionRunner
   TestFunctionRunner.@run
   ```

**Note:** Test dependencies must be listed in both `test/Project.toml` and
`test/$TestPackageName/Project.toml`.

Test package or its sub-modules can also be executed using
`TestFunctionRunner.run(module)`.
