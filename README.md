# TestFunctionRunner

A rather hacky solution to define tests in a package.  In particular, this
package takes care of some ugly details for dealing with:

* doctest (or any `eval`-based testing)
* tests that require loading test code for Distributed.jl

This package is aiming at a clear separation of test *definition* and test
*execution* phases.

## Quick start

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

## Defining tests

Following hooks/callbacks can be defined in *test modules*; i.e., modules whose
name start with `Test` followed by a capital letter.

### `test()`
### `test_*()`

A function defines a test if:

* its name is `test` or its name start with `test_`, and
* takes no arguments

### `module_context(f)`

A function named `module_context` defines the module context.  It can be used to
define setup and teardown for entire module and sub-module:

```JULIA
function module_context(f)
   setup()
   try
      f()
   finally
      teardown()
   end
end
```

where `f` is the function that runs the test functions of this module and its
sub-modules.

### Experimental

#### `timeout_of(test_function)`

A function named `timeout_of` can be used to customize timeout (in seconds) for
each test function.  Returning `nothing` means to fallback to the global
configuration.

#### `should_test_module()`

If a function named `should_test_module` exists and return `false`, all the
tests in the module and sub-modules are not tested.

#### `before_test_module()`

If a function named `before_test_module` exists, it is called before start
running the test inside this module.

#### `after_test_module()`

If a function named `after_test_module` exists, it is called after running the
test inside this module.

## Running tests

### Common options

`TestFunctionRunner.@run` and `TestFunctionRunner.run` support the following
options:

#### `$TEST_FUNCTION_RUNNER_JL_TIMEOUT`
#### `timeout`

Timeout (in seconds) for **each** test function. If the function takes more time
than the specified limit, **entire `julia` process** that is running the test
will be terminated. TestFunctionRunner.jl tries to print stack trace if
possible.

Note: This works only in Unix systems.

Environment variable `TEST_FUNCTION_RUNNER_JL_TIMEOUT` can be used for setting
the default value of `timeout`. Function and macro arguments overrides the
environment variable.

#### `$TEST_FUNCTION_RUNNER_JL_FASTFAIL`
#### `failfast`

If `true`, stop running the test upon the first failure.

Environment variable `TEST_FUNCTION_RUNNER_JL_FASTFAIL` can be used for setting
the default value of `failfast`. Function and macro arguments overrides the
environment variable.  Values `true`, `yes` and `1` (case insensitive) are
treated as `true`.

### `@run` options

#### `paths`

Additional load paths. Relative paths are resolved with respect to the parent
directory of the current file.  Example:
`TestFunctionRunner.@run(paths = ["../benchmark/MyBenchmarks/"])`.

#### `packages`

Specify packages to be tested by relative file paths; i.e., directories that
contain `Project.toml` or `JuliaProject.toml`.  A package at
`@__DIR__/$TestPackage/src/$TestPackage.jl` is tested if not specified.
