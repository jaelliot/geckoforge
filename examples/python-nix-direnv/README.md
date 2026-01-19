# Python Nix Development Environment Template

This directory provides a ready-to-use template for Python development using Nix flakes and direnv in geckoforge.

## Features

- **Python 3.14.2**: Latest stable Python with modern features
- **KERI Support**: Pre-configured with cryptographic libraries (libsodium, blake3)
- **Testing**: pytest with async support, coverage reporting
- **Type Checking**: mypy with strict configuration
- **Auto-activation**: direnv automatically loads environment when entering directory

## Quick Start

### 1. Copy Template to New Project

```bash
# Copy this template to your project directory
cp -r ~/git/geckoforge/examples/python-nix-direnv ~/git/my-project
cd ~/git/my-project
```

### 2. Allow direnv

```bash
direnv allow
```

The first load takes 1-2 minutes to build the Nix environment. Subsequent loads are instant (cached by nix-direnv).

### 3. Verify Setup

```bash
# Check Python version
python --version
# Output: Python 3.14.2

# Check installed packages
pip list

# Verify virtual environment
echo $VIRTUAL_ENV
# Output: /path/to/project/.venv
```

### 4. Start Development

```bash
# Create your package structure
mkdir -p src/my_package tests

# Write some code
cat > src/my_package/__init__.py << 'EOF'
"""My awesome package."""
__version__ = "0.1.0"

def greet(name: str) -> str:
    """Greet someone."""
    return f"Hello, {name}!"
EOF

# Write a test
cat > tests/test_my_package.py << 'EOF'
from my_package import greet

def test_greet():
    assert greet("World") == "Hello, World!"
EOF

# Run tests
pytest

# Type check
mypy src/
```

## Project Structure

```
python-nix-direnv/
├── .envrc              # direnv configuration (loads flake.nix)
├── flake.nix           # Nix environment definition
├── flake.lock          # Locked dependency versions (auto-generated)
├── requirements.txt    # Python dependencies
├── pytest.ini          # pytest configuration
├── mypy.ini           # Type checker configuration
├── README.md          # This file
├── .gitignore         # Git ignore rules (create this)
├── .venv/             # Virtual environment (auto-created, ignored by git)
└── src/               # Your source code (create this)
    └── my_package/
        ├── __init__.py
        └── ...
```

## File Explanations

### `.envrc`

Simple one-liner that tells direnv to use the Nix flake:

```bash
use flake
```

### `flake.nix`

Defines the Nix development environment:

- Python 3.14.2 interpreter
- Cryptographic libraries (libsodium, blake3)
- Build tools (gcc, make, pkg-config)
- `shellHook` that creates `.venv` and installs packages

### `requirements.txt`

Python packages installed via pip:

- **KERI libraries**: keripy, hio
- **Testing**: pytest, pytest-asyncio, pytest-mock, pytest-cov
- **Type checking**: mypy
- **Utilities**: requests, msgpack, cbor2

Add your project dependencies here and run `direnv reload` to install them.

### `pytest.ini`

pytest configuration:

- Test discovery patterns
- Async test support (`asyncio_mode = auto`)
- Code coverage settings
- Custom markers (slow, integration, unit, keri)

### `mypy.ini`

Type checker configuration:

- Strict type checking enabled
- Ignores missing type stubs for KERI libraries
- Relaxed rules for test files

## Common Workflows

### Adding New Dependencies

```bash
# 1. Add to requirements.txt
echo "fastapi>=0.104.0" >> requirements.txt

# 2. Reload environment (automatically installs)
direnv reload

# 3. Verify installation
pip list | grep fastapi
```

### Running Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_my_package.py

# Run with coverage
pytest --cov=src --cov-report=html

# View coverage report
xdg-open htmlcov/index.html

# Run only fast tests (exclude slow ones)
pytest -m "not slow"

# Run specific marker
pytest -m keri
```

### Type Checking

```bash
# Check entire project
mypy .

# Check specific directory
mypy src/my_package/

# Strict mode
mypy --strict src/

# Show error codes
mypy --show-error-codes src/
```

### Code Linting

```bash
# Lint with ruff (fast)
ruff check .

# Auto-fix issues
ruff check --fix .

# Format code
ruff format .
```

## KERI Development

This template is pre-configured for KERI development with:

- **libsodium**: Ed25519 and X25519 cryptography
- **blake3**: Fast cryptographic hashing
- **keripy**: Core KERI protocol implementation
- **hio**: Async I/O framework

### KERI Quick Example

```python
# example_keri.py
from keri.app import habbing

def create_identifier(name: str) -> str:
    """Create a new KERI identifier."""
    with habbing.Habitat(name=name, temp=True) as hab:
        hab.makeInception()
        return hab.pre

if __name__ == "__main__":
    aid = create_identifier("myapp")
    print(f"Created identifier: {aid}")
```

Run it:

```bash
python example_keri.py
```

See [docs/keri-development.md](../../docs/keri-development.md) for comprehensive KERI guide.

## Customization

### Change Python Version

Edit `flake.nix`:

```nix
systemDeps = with pkgs; [
  python313  # Change to python313 or python312
  python313Packages.pip
  # ...
];
```

Then reload: `direnv reload`

### Add System Dependencies

For packages requiring C libraries, add to `flake.nix`:

```nix
systemDeps = with pkgs; [
  python314
  
  # Add your libraries
  postgresql    # PostgreSQL client library
  openssl       # OpenSSL
  zlib          # Compression
  
  # Existing libs...
];
```

### Use Poetry Instead of pip

1. Add poetry to `flake.nix`:

```nix
systemDeps = with pkgs; [
  python314
  poetry
  # ...
];
```

2. Replace `shellHook` in `flake.nix`:

```nix
shellHook = ''
  export POETRY_VIRTUALENVS_IN_PROJECT=true
  
  if [ ! -d .venv ]; then
    poetry install
  fi
  
  echo "Poetry environment ready!"
'';
```

3. Create `pyproject.toml` instead of `requirements.txt`

## Troubleshooting

### Environment Not Loading

```bash
# Check direnv status
direnv status

# Reload manually
direnv reload

# Check for errors in flake.nix
nix flake check
```

### Packages Not Installing

```bash
# Check if virtual environment exists
ls -la .venv/bin/python

# Manually recreate
rm -rf .venv
direnv reload
```

### VS Code Not Finding Python

1. Restart VS Code
2. Command Palette → "Python: Select Interpreter"
3. Choose `.venv/bin/python`

### Library Not Found Errors

If you see "cannot find -lsodium" or similar:

1. Verify library in `flake.nix` under `systemDeps`
2. Check `LD_LIBRARY_PATH` is set in `shellHook`
3. Reload: `direnv reload`

## Git Setup

Create `.gitignore`:

```gitignore
# Virtual environment
.venv/
__pycache__/
*.pyc

# Testing
.pytest_cache/
.coverage
htmlcov/

# Type checking
.mypy_cache/

# direnv
.direnv/

# Nix
result
result-*
```

Initialize git:

```bash
git init
git add .
git commit -m "Initial commit from python-nix-direnv template"
```

## VS Code Integration

geckoforge's VS Code is pre-configured for this workflow. Just open the project:

```bash
code .
```

Features automatically work:

- Python interpreter detection (`.venv/bin/python`)
- pytest test discovery and execution
- mypy type checking
- IntelliSense with installed packages
- Debugging

## Next Steps

- Read [Python Development Guide](../../docs/python-development.md)
- For KERI projects: [KERI Development Guide](../../docs/keri-development.md)
- Review Home-Manager modules: [Nix Modules Usage](../../docs/nix-modules-usage.md)

## Support

For issues or questions:

- Check [Python Development Troubleshooting](../../docs/python-development.md#troubleshooting)
- Review geckoforge documentation in `docs/`
- File an issue in the geckoforge repository

Happy coding! 🐍
