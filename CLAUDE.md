# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **zig-nfl-field**, a zero-dependency Zig library that provides NFL field representation and coordinate system functionality. The library implements precise field geometry, coordinate validation, and spatial calculations for NFL game development.

## Commands

### Build Commands
```bash
# Build the static library
zig build

# Run all tests
zig build test

# Run benchmarks
zig build benchmark

# Run benchmark tests
zig build test:benchmark
```

### Development Commands
```bash
# Run specific test file
zig test lib/field.test.zig

# Run tests with optimization
zig build test -Doptimize=ReleaseSafe
zig build test -Doptimize=ReleaseFast

# Test specific categories (using filter)
zig test lib/field.test.zig --test-filter "unit:"
zig test lib/field.test.zig --test-filter "integration:"
```

## Architecture

### Core Components

**Field Module (`lib/field.zig`)**
- Primary entry point for the library
- Exports `Field` struct for NFL field representation with standard dimensions (120x53.33 yards)
- Exports `Coordinate` struct for position tracking and distance calculations
- Provides boundary checking and zone detection (endzones vs playing field)

**Utility Structure (`lib/utils/`)**
- `coordinate/`: Coordinate system utilities and transformations
- `yardline/`: Yardline calculations and hash mark systems  
- `zone/`: Field zone detection and classification

### Build System

The project uses Zig's build system with:
- **Module Definition**: Exports "field" module for external consumption
- **Static Library**: Builds `libnflField.a` for linking
- **Testing**: Comprehensive test suite with `lib/field.test.zig`
- **Benchmarking**: Performance testing in `benchmarks/field_bench.zig`

### Library Design

- **Zero Dependencies**: Pure Zig implementation with no external dependencies
- **Coordinate System**: Origin (0,0) at home endzone back line, left sideline
- **Precision**: Uses f32 for all measurements in yards
- **Validation**: Built-in boundary checking and coordinate validation
- **Modular**: Clean separation between core field logic and utility functions

## Code Style (Maysara Code Style - MCS)

This project follows the Maysara Code Style guidelines defined in `docs/MCS.md`. Key requirements:

### File Structure
- Standard headers with repo/author information
- Section demarcation using decorative borders: `╔═══ SECTION ═══╗`
- Subsection borders: `┌─── SUBSECTION ───┐`
- All code within sections indented by 4 spaces

### Test Organization  
- Tests follow strict categorization in `lib/field.test.zig`:
  - `unit`: Individual function testing
  - `integration`: Component interaction testing  
  - `e2e`: Complete workflow testing
  - `scenario`: Real-world NFL rule scenarios
  - `performance`: Performance requirement validation
  - `stress`: Extreme condition testing

### Test Naming Convention
```zig
test "<category>: <component>: <description>" {
    // Test implementation
}
```

### Documentation Standards
- Function documentation with parameters and return values
- Implementation comments for complex logic
- Memory safety with `std.testing.allocator` in tests

## Testing Conventions

Comprehensive testing guidelines are defined in `docs/TESTING_CONVENTIONS.md`:

- **Coverage Requirements**: 100% for public functions, 80% for integrations
- **Memory Safety**: All tests use `std.testing.allocator` with proper cleanup
- **Test Isolation**: Each test creates independent instances
- **Performance Benchmarks**: Sub-microsecond requirements for core operations

## Project Status

The project is in active development with structured issues tracking implementation progress in the `issues/` directory. Current focus areas include coordinate system implementation, field validation, and comprehensive test coverage.