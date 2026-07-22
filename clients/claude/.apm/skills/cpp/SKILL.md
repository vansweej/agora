---
name: cpp
description: >
  Use when working in a C++ project or when the task involves C++ code,
  CMake, or Make. Triggers on: c++, cpp, cmake, CMakeLists, clang, gcc,
  ctest, conan, vcpkg, clang-tidy, clang-format.
---

<!-- DO NOT EDIT — generated from skills/cpp/SKILL.md by agora/renderers/opencode-to-claude.md -->

# C++

Language-specific rules for C++ projects. Load this skill when working in
any repository that uses CMake or C++ source files.

## Core Principles

- Prefer RAII for all resource management — never manage resources manually
- Use smart pointers (`std::unique_ptr`, `std::shared_ptr`) over raw owning pointers
- Favor value semantics over pointer semantics where practical
- Apply `const` correctness everywhere: parameters, member functions, local variables
- Keep functions small and composable
- Target C++20 or later (as specified in `CMakeLists.txt`)

## Error Handling

- Use exceptions for truly exceptional, unrecoverable conditions
- Prefer `std::optional<T>` for values that may not exist
- Prefer `std::expected<T, E>` (C++23) or a Result-like type for recoverable errors
- Never ignore return values of functions that can fail — use `[[nodiscard]]`
- Avoid C-style error codes (`errno`, magic integers) in new code

## Memory & Performance

- Avoid unnecessary heap allocations — prefer stack allocation
- Prefer `std::string_view` and `std::span` over copies when borrowing suffices
- Use move semantics (`std::move`) where appropriate to avoid copies
- Avoid premature optimization — profile with a real tool before changing hot paths
- Prefer `std::array` over C-style arrays; prefer `std::vector` over manual dynamic arrays

## Modern C++ Idioms

- Use structured bindings: `auto [key, value] = ...`
- Use range-based for loops over index-based loops
- Prefer `<algorithm>` and `<ranges>` over raw loops
- Use `enum class` over plain `enum` to avoid implicit conversions
- Use `constexpr` for compile-time computation
- Use `[[nodiscard]]` on functions whose return values must not be ignored
- Prefer `nullptr` over `NULL` or `0` for pointer initialization

## Build & Tooling

- Use CMake as the build system (minimum version 3.20)
- Run `clang-format` before declaring done; fix all formatting issues
- Run `clang-tidy` and fix all warnings
- Use `ctest` for test execution
- Standard project layout: `src/` for source, `tests/` for test files,
  `include/` for public headers
- Always run inside the Nix dev shell if a `flake.nix` is present: `nix develop --command <cmd>`

## Testing

- Use a testing framework: Catch2 or Google Test
- Target ≥ 90% coverage; exclude UI and GPU code from measurement
- Use `ctest` to run the test suite: `ctest --test-dir build --output-on-failure`
- Structure tests with `TEST_CASE` / `SECTION` (Catch2) or `TEST` / `TEST_F` (GTest)
- Co-locate unit tests near source or place them under `tests/`
- Register all test executables with `add_test()` or `gtest_discover_tests()` in `CMakeLists.txt`

## Code Review

- Flag raw `new`/`delete` in production code — should use RAII or smart pointers
- Flag missing `virtual` destructors in base classes intended for polymorphism
- Check for resource leaks: file handles, sockets, locks not managed by RAII
- Verify `const`-correctness on function parameters and member functions
- Flag `reinterpret_cast` and `const_cast` — both require a clear justification comment

## Code Generation

- Always generate compilable code
- Avoid placeholders or stub implementations in production paths
- Prefer clarity over cleverness
- Include all necessary `#include` directives — do not rely on transitive includes
- Add include guards or `#pragma once` to every header file
