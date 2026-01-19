# Python Development with Nix and direnv

This guide explains how to set up reproducible Python development environments using Nix flakes and direnv in geckoforge.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Understanding the Hybrid Approach](#understanding-the-hybrid-approach)
- [Creating a Python Project](#creating-a-python-project)
- [VS Code Integration](#vs-code-integration)
- [Testing with pytest](#testing-with-pytest)
- [Type Checking with mypy](#type-checking-with-mypy)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Overview

### Why Nix + direnv?

**Reproducibility**: Nix provides deterministic builds. The same `flake.nix` produces identical environments across machines.

**Isolation**: Each project gets its own environment. No more global package conflicts.

**Automatic Activation**: direnv loads the environment when you `cd` into the project directory. No manual `source venv/bin/activate`.

**Fast**: nix-direnv caches the environment. Subsequent loads are instant.

### The Hybrid Approach

geckoforge uses a **hybrid workflow**:

1. **Nix provides system dependencies**:
   - Python interpreter (3.14.2)
   - C libraries (libsodium, openssl, etc.)
   - Build tools (gcc, make, pkg-config)

2. **pip manages Python packages**:
   - Installed in a local `.venv` directory
   - Uses `requirements.txt` or `pyproject.toml`
   - Works with any PyPI package

**Why hybrid?** Not all Python packages are in nixpkgs, and pip packaging is the Python ecosystem standard. This approach gives you reproducible system dependencies while maintaining flexibility for Python packages.

## Quick Start

### 1. Create a New Python Project

```bash
# Copy the template
cp -r ~/git/geckoforge/examples/python-nix-direnv my-project
cd my-project

# Allow direnv to load the environment
direnv allow
```

The environment will automatically:
- Build the Nix shell with Python 3.14.2
- Create a `.venv` directory
- Install packages from `requirements.txt`
- Activate the virtual environment

### 2. Verify Setup

```bash
# Check Python version
python --version  # Should show Python 3.14.2

# Check installed packages
pip list

# Verify direnv is active (prompt shows "direnv")
echo $VIRTUAL_ENV  # Should point to .venv
```

### 3. Start Coding

```python
# test_example.py
def add(a, b):
    return a + b

def test_add():
    assert add(2, 3) == 5
```

```bash
# Run tests
pytest

# Type check
mypy .
```

## Understanding the Hybrid Approach

### Project Structure

```
my-project/
├── .envrc              # direnv configuration
├── flake.nix           # Nix environment definition
├── flake.lock          # Locked dependency versions
├── requirements.txt    # Python packages
├── pytest.ini          # pytest configuration
├── mypy.ini           # Type checker configuration
├── .venv/             # Virtual environment (auto-created)
│   └── bin/python
└── src/
    └── my_package/
```

### How It Works

1. **`.envrc` triggers direnv**:
   ```bash
   use flake
   ```

2. **`flake.nix` defines the Nix shell**:
   - Specifies Python 3.14.2
   - Includes system libraries (libsodium, etc.)
   - Runs `shellHook` to create `.venv` and install packages

3. **`.venv` contains Python packages**:
   - Managed by pip
   - Excluded from git (`.venv` in `.gitignore`)
   - Recreated automatically if deleted

## Creating a Python Project

### Step 1: Create Directory Structure

```bash
mkdir my-project
cd my-project
```

### Step 2: Create `flake.nix`

```nix
{
  description = "Python development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # System dependencies (C libraries, build tools)
        systemDeps = with pkgs; [
          python314
          python314Packages.pip
          python314Packages.virtualenv
          
          # Cryptographic libraries (common for security/blockchain work)
          libsodium
          blake3
          
          # Build tools
          gcc
          gnumake
          pkg-config
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = systemDeps;
          
          shellHook = ''
            # Create virtual environment if it doesn't exist
            if [ ! -d .venv ]; then
              echo "Creating virtual environment..."
              python -m venv .venv
            fi
            
            # Activate virtual environment
            source .venv/bin/activate
            
            # Upgrade pip
            pip install --upgrade pip > /dev/null
            
            # Install/update Python packages
            if [ -f requirements.txt ]; then
              echo "Installing Python packages..."
              pip install -r requirements.txt
            fi
            
            echo "Python environment ready!"
            echo "Python: $(python --version)"
            echo "Location: $(which python)"
          '';
        };
      }
    );
}
```

### Step 3: Create `requirements.txt`

```txt
# Testing
pytest>=8.0.0
pytest-asyncio>=0.23.0
pytest-mock>=3.12.0
pytest-cov>=4.1.0

# Type checking
mypy>=1.8.0

# Linting
ruff>=0.1.0

# Your project dependencies
requests>=2.31.0
# Add more as needed
```

### Step 4: Create `.envrc`

```bash
use flake
```

### Step 5: Allow direnv

```bash
direnv allow
```

The environment will build automatically. This takes 1-2 minutes the first time, then is cached.

### Step 6: Configure Testing

Create `pytest.ini`:

```ini
[pytest]
testpaths = tests src
python_files = test_*.py *_test.py
python_classes = Test*
python_functions = test_*
addopts =
    --verbose
    --strict-markers
    --cov=src
    --cov-report=term-missing
    --cov-report=html
asyncio_mode = auto
```

Create `mypy.ini`:

```ini
[mypy]
python_version = 3.14
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
check_untyped_defs = True
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
warn_unreachable = True
strict_equality = True
```

## VS Code Integration

geckoforge's VS Code configuration (in `home/modules/vscode.nix`) is already set up for this workflow:

### Automatic Features

- **Python interpreter**: Automatically uses `.venv/bin/python`
- **Testing**: pytest integration enabled
- **Type checking**: mypy enabled
- **IntelliSense**: Works with your virtual environment

### Verify Integration

1. Open VS Code in your project: `code .`
2. Check status bar for Python interpreter: Should show `.venv/bin/python`
3. Open Command Palette (Ctrl+Shift+P): "Python: Select Interpreter"
   - Should auto-detect `.venv/bin/python`

### Running Tests in VS Code

- **Run all tests**: Click "Run Tests" in Test Explorer
- **Run single test**: Click green arrow next to test function
- **Debug test**: Right-click test → "Debug Test"

### Keyboard Shortcuts

- `Ctrl+Shift+P` → "Python: Run All Tests"
- `Ctrl+Shift+P` → "Python: Run Current Test File"

## Testing with pytest

### Basic Usage

```bash
# Run all tests
pytest

# Run specific file
pytest tests/test_example.py

# Run specific test
pytest tests/test_example.py::test_function_name

# Run with coverage
pytest --cov=src --cov-report=html

# Run in verbose mode
pytest -v
```

### Testing Async Code

```python
# test_async.py
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await some_async_function()
    assert result == expected
```

pytest-asyncio is configured to auto-detect async tests (see `pytest.ini`).

### Using Mocks

```python
# test_with_mock.py
from unittest.mock import Mock, patch

def test_with_mock(mocker):
    # Using pytest-mock
    mock_obj = mocker.patch('module.function')
    mock_obj.return_value = 42
    
    result = call_function_that_uses_module()
    assert result == 42
    mock_obj.assert_called_once()
```

## Type Checking with mypy

### Basic Usage

```bash
# Check entire project
mypy .

# Check specific file
mypy src/my_module.py

# Strict mode
mypy --strict src/
```

### Adding Type Hints

```python
# example.py
from typing import List, Optional

def process_items(items: List[str], limit: Optional[int] = None) -> List[str]:
    """Process a list of items."""
    if limit:
        return items[:limit]
    return items

# mypy will catch errors:
result = process_items([1, 2, 3])  # Error: Expected List[str], got List[int]
```

### Configuration

Edit `mypy.ini` to adjust strictness:

```ini
[mypy]
# Disable specific checks
disallow_untyped_defs = False  # Allow functions without type hints

# Per-module configuration
[mypy-tests.*]
disallow_untyped_defs = False  # Relaxed rules for tests
```

## Troubleshooting

### direnv Not Loading

**Symptom**: Environment doesn't activate when entering directory

**Solutions**:
```bash
# Allow direnv (required after creating/editing .envrc)
direnv allow

# Check direnv status
direnv status

# Reload manually
direnv reload
```

### Packages Not Installing

**Symptom**: `pip install` fails or packages not found

**Solutions**:
```bash
# Check if in virtual environment
echo $VIRTUAL_ENV  # Should show path to .venv

# Manually activate venv
source .venv/bin/activate

# Reinstall packages
pip install -r requirements.txt

# Clear pip cache
pip cache purge
```

### Python Version Mismatch

**Symptom**: `python --version` shows wrong version

**Solutions**:
```bash
# Check if direnv is active
echo $VIRTUAL_ENV

# Verify flake.nix specifies python314
grep python314 flake.nix

# Rebuild environment
rm -rf .venv
direnv reload
```

### Missing System Libraries

**Symptom**: Error like "cannot find -lsodium" or "fatal error: sodium.h"

**Solution**: Add the library to `flake.nix`:

```nix
systemDeps = with pkgs; [
  python314
  libsodium      # Add missing library
  openssl
  # ...
];
```

Then reload:
```bash
direnv reload
```

### VS Code Not Finding Interpreter

**Symptom**: VS Code shows "Python interpreter not found"

**Solutions**:
1. Restart VS Code
2. Command Palette → "Python: Select Interpreter" → Choose `.venv/bin/python`
3. Check that `.venv` exists: `ls -la .venv/bin/python`

### Slow Environment Loading

**Symptom**: direnv takes a long time to load

**Solutions**:
```bash
# Check if nix-direnv is enabled (should be cached)
grep nix-direnv ~/.config/direnv/direnvrc

# First load is slow (building), subsequent loads should be instant
# If always slow, rebuild cache:
rm -rf ~/.cache/direnv
direnv reload
```

## Advanced Usage

### Multiple Python Versions

To switch Python versions, edit `flake.nix`:

```nix
# Use Python 3.13 instead of 3.14
systemDeps = with pkgs; [
  python313
  python313Packages.pip
  # ...
];
```

### Adding System Dependencies

For projects requiring specific C libraries:

```nix
systemDeps = with pkgs; [
  python314
  
  # Database clients
  postgresql
  mysql
  
  # Compression
  zlib
  bzip2
  
  # Image processing
  libjpeg
  libpng
  
  # Your library here
];
```

### Using Poetry Instead of pip

Replace `shellHook` in `flake.nix`:

```nix
shellHook = ''
  # Use Poetry for dependency management
  export POETRY_VIRTUALENVS_IN_PROJECT=true
  
  if [ ! -d .venv ]; then
    poetry install
  fi
'';
```

And add `poetry` to system dependencies:

```nix
systemDeps = with pkgs; [
  python314
  poetry
];
```

### Sharing flake.nix Across Projects

Create a template repository:

```bash
mkdir ~/git/python-template
cd ~/git/python-template

# Add flake.nix, .envrc, pytest.ini, mypy.ini
# Commit to git

# Use in new projects:
git clone ~/git/python-template my-new-project
cd my-new-project
direnv allow
```

### CI/CD Integration

Your Nix flake works in CI systems:

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: cachix/install-nix-action@v24
        with:
          nix_path: nixpkgs=channel:nixos-24.05
      
      - name: Run tests
        run: |
          nix develop --command pytest
```

## See Also

- [KERI Development](keri-development.md) - Specialized guide for KERI projects
- [Nix Modules Usage](nix-modules-usage.md) - Overview of Home-Manager modules
- [VS Code Migration](vscode-migration.md) - Migrating existing VS Code setup
- [Example Template](../examples/python-nix-direnv/) - Ready-to-use project template

## Additional Resources

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [direnv Documentation](https://direnv.net/)
- [nix-direnv GitHub](https://github.com/nix-community/nix-direnv)
- [pytest Documentation](https://docs.pytest.org/)
- [mypy Documentation](https://mypy.readthedocs.io/)
