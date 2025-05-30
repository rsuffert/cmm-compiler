# C-- Compiler

A compiler for the **C--** language using **JFlex** and **Byacc/J**. It performs lexical, syntax, and semantic analysis.

## Features
- Lexical and syntax analysis.
- Semantic checks: type, scope, and function validation.
- Comprehensive test suite (various test programs in the `test` folder, categorized by and named after their semantic feature).

## Prerequisites

- **Java**: Ensure you have Java installed on your system.
- **JFlex**: The `jflex.jar` file is included in the project.
- **Byacc/J**: The `yacc.linux` binary is included in the project.

## Usage

You may use the Makefile to build the compiler and run your own C-- program file with the below commands. The output will be either <span style="color:green">Success!</span> or <span style="color:red">[ERROR-TYPE] ERROR: [ERROR-MESSAGE]</span>, where `[ERROR-TYPE]` is either `LEXICAL`, `SYNTAX`, or `SEMANTIC`.

```bash
make
java Parser <cmm-prog-file>
```

For automatically running all the unit tests and getting a report, use the below command. The output is pretty self-explanatory.

```bash
make run-tests
```

## Notices

- The original C-- grammar does not support array types. However, this compiler has been modified to include _some_ support to arrays. One-dimensional arrays are supported as local/global variables and function parameters, but _not_ as return types. _n_-dimensional arrays (where n > 1) are not supported at all. Violating these rules for arrays usage will be caught by the compiler as a syntax error.
- Lexical and semantic errors are reported with detailed error messages, but error recovery has not been implemented for syntax errors, so the error messages are as simple as "syntax error".