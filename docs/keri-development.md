# KERI Development Guide

This guide covers setting up and developing with KERI (Key Event Receipt Infrastructure) libraries in geckoforge using Nix-based Python environments.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [KERI Architecture](#keri-architecture)
- [Setting Up a KERI Project](#setting-up-a-keri-project)
- [Core KERI Libraries](#core-keri-libraries)
- [Testing KERI Applications](#testing-keri-applications)
- [Type Checking KERI Code](#type-checking-keri-code)
- [Common KERI Patterns](#common-keri-patterns)
- [Debugging KERI Applications](#debugging-keri-applications)
- [Performance Considerations](#performance-considerations)

## Overview

### What is KERI?

**KERI (Key Event Receipt Infrastructure)** is a decentralized identity system that provides:

- **Self-sovereign identity**: Users control their own identifiers
- **Key rotation**: Secure key management with pre-rotation
- **Event sourcing**: Immutable log of key events
- **Verifiable credentials**: Cryptographically signed attestations

KERI is developed by the [KERI Foundation](https://keri.one/) and is designed for high-security applications like supply chain, healthcare, and financial services.

### KERI in geckoforge

geckoforge provides a Nix-based development environment optimized for KERI development:

- **Cryptographic dependencies**: libsodium, blake3 pre-installed
- **Python 3.14.2**: Latest stable Python with modern async features
- **Testing framework**: pytest with async support
- **Type checking**: mypy for catching errors early

## Quick Start

### 1. Create KERI Project from Template

```bash
# Copy the KERI-ready template
cp -r ~/git/geckoforge/examples/python-nix-direnv my-keri-project
cd my-keri-project

# Allow direnv
direnv allow
```

The environment automatically installs:
- `hio` - Asynchronous I/O library for KERI
- `keripy` - Core KERI implementation
- pytest with async support
- mypy for type checking

### 2. Verify KERI Installation

```bash
# Check Python version
python --version  # Python 3.14.2

# Verify KERI packages
python -c "import keri; print(f'KERIpy: {keri.__version__}')"
python -c "import hio; print(f'hio: {hio.__version__}')"

# Check cryptographic libraries
python -c "import nacl; print('libsodium: OK')"
```

### 3. Run Example KERI Code

```python
# test_keri_basic.py
from keri.core import coring
from keri.app import habbing

def test_create_identifier():
    """Create a basic KERI identifier."""
    # Create a habitat (KERI environment)
    with habbing.Habitat(name='test', temp=True) as hab:
        # Create an inception event (new identifier)
        hab.makeInception()
        
        # Verify identifier was created
        assert hab.pre  # Prefix (identifier)
        print(f"Created identifier: {hab.pre}")
```

```bash
pytest -v test_keri_basic.py
```

## KERI Architecture

### Core Components

```
┌─────────────────────────────────────────────┐
│           KERI Application Layer            │
│  (Your code using keripy, hio)             │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│              KERIpy Library                 │
│  • Core: coring (events, keys)             │
│  • App: habbing (habitats, agents)         │
│  • Database: basing (LMDB storage)         │
│  • Networking: keeping (HTTP, TCP)         │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│            hio (Async I/O)                  │
│  • Event loop                               │
│  • Async primitives                         │
│  • Timers and scheduling                    │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│        Cryptographic Libraries              │
│  • libsodium (Ed25519, X25519)             │
│  • blake3 (hashing)                         │
└─────────────────────────────────────────────┘
```

### Key Concepts

**Habitat**: A KERI environment containing:
- **Prefix (pre)**: The identifier (e.g., `EBXoO...`)
- **Key state**: Current public keys
- **Event log**: History of key events

**Key Events**:
- **Inception (icp)**: Create new identifier
- **Rotation (rot)**: Rotate keys
- **Interaction (ixn)**: Non-key-related events
- **Delegated inception (dip)**: Create delegated identifier

**Witnesses**: Nodes that observe and confirm events

**Watchers**: Nodes that verify and store event logs

## Setting Up a KERI Project

### Project Structure

```
my-keri-project/
├── .envrc                  # direnv configuration
├── flake.nix               # Nix environment with libsodium, blake3
├── requirements.txt        # KERI libraries (hio, keripy)
├── pytest.ini              # Testing configuration
├── mypy.ini               # Type checking configuration
├── src/
│   └── my_keri_app/
│       ├── __init__.py
│       ├── identifiers.py  # Identifier management
│       ├── credentials.py  # Verifiable credentials
│       └── witnesses.py    # Witness interaction
├── tests/
│   ├── test_identifiers.py
│   ├── test_credentials.py
│   └── test_witnesses.py
└── scripts/
    ├── create_identifier.py
    └── issue_credential.py
```

### flake.nix for KERI

```nix
{
  description = "KERI development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        systemDeps = with pkgs; [
          python314
          python314Packages.pip
          python314Packages.virtualenv
          
          # KERI cryptographic dependencies
          libsodium       # Ed25519, X25519 cryptography
          blake3          # Fast cryptographic hashing
          
          # Build tools
          gcc
          gnumake
          pkg-config
          
          # Optional: Database tools (KERI uses LMDB)
          lmdb
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = systemDeps;
          
          # Set library paths for cryptographic libraries
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.libsodium pkgs.blake3 ];
          
          shellHook = ''
            # Create virtual environment
            if [ ! -d .venv ]; then
              echo "Creating virtual environment..."
              python -m venv .venv
            fi
            
            source .venv/bin/activate
            pip install --upgrade pip > /dev/null
            
            # Install KERI dependencies
            if [ -f requirements.txt ]; then
              echo "Installing KERI libraries..."
              pip install -r requirements.txt
            fi
            
            echo "KERI development environment ready!"
            echo "Python: $(python --version)"
            echo "libsodium: $(pkg-config --modversion libsodium)"
          '';
        };
      }
    );
}
```

### requirements.txt for KERI

```txt
# Core KERI libraries
keripy>=2.0.0
hio>=0.6.0

# Testing
pytest>=8.0.0
pytest-asyncio>=0.23.0
pytest-mock>=3.12.0
pytest-cov>=4.1.0

# Type checking
mypy>=1.8.0

# Linting
ruff>=0.1.0

# Additional utilities
requests>=2.31.0
msgpack>=1.0.0
cbor2>=5.4.0
```

## Core KERI Libraries

### hio - Async I/O Framework

**Purpose**: Lightweight async I/O library for KERI

```python
# Example: hio async pattern
from hio.base import doing

class MyWorker(doing.Doable):
    """Async worker using hio."""
    
    def __init__(self):
        super().__init__()
        self.counter = 0
    
    async def do(self):
        """Main work loop."""
        while not self.done:
            self.counter += 1
            print(f"Count: {self.counter}")
            await asyncio.sleep(1)

# Usage
async def main():
    worker = MyWorker()
    await worker.do()
```

### keripy - Core KERI Implementation

**Purpose**: Complete KERI protocol implementation

#### Creating Identifiers

```python
from keri.app import habbing
from keri.core import coring

# Create a habitat with temporary database
with habbing.Habitat(name='myapp', temp=True) as hab:
    # Create inception event (new identifier)
    hab.makeInception()
    
    print(f"Identifier: {hab.pre}")
    print(f"Public key: {hab.kever.verfers[0].qb64}")
```

#### Key Rotation

```python
from keri.app import habbing

with habbing.Habitat(name='myapp', temp=True) as hab:
    # Create identifier
    hab.makeInception()
    old_keys = hab.kever.verfers
    
    # Rotate keys
    hab.rotate()
    new_keys = hab.kever.verfers
    
    assert old_keys != new_keys
    print(f"Rotated from {old_keys[0].qb64} to {new_keys[0].qb64}")
```

#### Issuing Verifiable Credentials

```python
from keri.app import habbing, credentialing
from keri.core import scheming

with habbing.Habitat(name='issuer', temp=True) as issuer_hab:
    issuer_hab.makeInception()
    
    # Define credential schema
    schema = {
        "$id": "https://example.com/schemas/employee",
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "position": {"type": "string"},
            "employee_id": {"type": "string"}
        }
    }
    
    # Issue credential
    credential = {
        "name": "Alice Smith",
        "position": "Software Engineer",
        "employee_id": "E12345"
    }
    
    # Sign and issue (simplified example)
    registry = credentialing.Registry(hby=issuer_hab)
    vc = registry.issue(
        issuer=issuer_hab.pre,
        schema=schema,
        credential=credential
    )
```

## Testing KERI Applications

### Basic Test Setup

```python
# tests/test_identifiers.py
import pytest
from keri.app import habbing

@pytest.fixture
def habitat():
    """Create a temporary habitat for testing."""
    with habbing.Habitat(name='test', temp=True) as hab:
        hab.makeInception()
        yield hab

def test_identifier_creation(habitat):
    """Test that identifier is created correctly."""
    assert habitat.pre
    assert habitat.pre.startswith('E')  # Ed25519 prefix
    assert len(habitat.pre) == 44  # Base64 encoded
```

### Testing Async KERI Code

```python
# tests/test_async_keri.py
import pytest
from keri.app import habbing
from hio.base import doing

@pytest.mark.asyncio
async def test_async_habitat():
    """Test async operations in KERI."""
    with habbing.Habitat(name='test', temp=True) as hab:
        hab.makeInception()
        
        # Simulate async operation
        await doing.sleep(0.1)
        
        # Rotate keys asynchronously
        hab.rotate()
        
        assert hab.kever.sn == 1  # Sequence number incremented
```

### Testing with Mocks

```python
# tests/test_with_mocks.py
import pytest
from unittest.mock import Mock, patch
from keri.app import habbing

def test_witness_communication(mocker):
    """Test witness communication with mocks."""
    # Mock network call to witness
    mock_witness = mocker.patch('keri.core.eventing.Kevery.processReceipt')
    
    with habbing.Habitat(name='test', temp=True) as hab:
        hab.makeInception()
        
        # Code that would contact witness
        # mock_witness should be called
        
    mock_witness.assert_called()
```

### Coverage for KERI Code

```bash
# Run tests with coverage
pytest --cov=src --cov-report=html

# View coverage report
xdg-open htmlcov/index.html
```

## Type Checking KERI Code

### mypy Configuration for KERI

```ini
# mypy.ini
[mypy]
python_version = 3.14
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
check_untyped_defs = True
no_implicit_optional = True

# KERI libraries don't have complete type stubs
[mypy-keri.*]
ignore_missing_imports = True

[mypy-hio.*]
ignore_missing_imports = True
```

### Adding Type Hints to KERI Code

```python
# src/my_keri_app/identifiers.py
from typing import Optional, List
from keri.app.habbing import Habitat
from keri.core.coring import Verfer

def create_identifier(name: str, temp: bool = True) -> str:
    """Create a new KERI identifier.
    
    Args:
        name: Habitat name
        temp: Use temporary database
        
    Returns:
        The identifier prefix (AID)
    """
    with Habitat(name=name, temp=temp) as hab:
        hab.makeInception()
        return hab.pre

def get_public_keys(hab: Habitat) -> List[str]:
    """Get current public keys for habitat.
    
    Args:
        hab: KERI habitat
        
    Returns:
        List of public keys in Base64 format
    """
    return [verfer.qb64 for verfer in hab.kever.verfers]
```

### Running Type Checks

```bash
# Check entire project
mypy src/

# Check specific module
mypy src/my_keri_app/identifiers.py

# Strict mode (catches more issues)
mypy --strict src/my_keri_app/
```

## Common KERI Patterns

### Pattern 1: Identifier Lifecycle Management

```python
# src/my_keri_app/lifecycle.py
from keri.app import habbing
from typing import Optional
import os

class IdentifierManager:
    """Manages KERI identifier lifecycle."""
    
    def __init__(self, name: str, db_path: Optional[str] = None):
        self.name = name
        self.db_path = db_path or f".keri/db/{name}"
        self._hab: Optional[habbing.Habitat] = None
    
    def create(self) -> str:
        """Create new identifier."""
        os.makedirs(self.db_path, exist_ok=True)
        
        with habbing.Habitat(name=self.name, base=self.db_path) as hab:
            hab.makeInception()
            return hab.pre
    
    def rotate_keys(self) -> None:
        """Rotate identifier keys."""
        with habbing.Habitat(name=self.name, base=self.db_path) as hab:
            hab.rotate()
    
    def get_identifier(self) -> str:
        """Get current identifier."""
        with habbing.Habitat(name=self.name, base=self.db_path) as hab:
            return hab.pre

# Usage
manager = IdentifierManager("myapp")
aid = manager.create()
print(f"Created: {aid}")

# Later: rotate keys
manager.rotate_keys()
```

### Pattern 2: Witness Integration

```python
# src/my_keri_app/witnesses.py
from keri.app import habbing
from typing import List

class WitnessManager:
    """Manages witness configuration."""
    
    def __init__(self, habitat: habbing.Habitat):
        self.habitat = habitat
    
    def configure_witnesses(self, witness_urls: List[str]) -> None:
        """Configure witnesses for identifier.
        
        Args:
            witness_urls: List of witness URLs
        """
        # Add witnesses to habitat
        for url in witness_urls:
            self.habitat.witnesses.append(url)
    
    def query_witnesses(self) -> dict:
        """Query all witnesses for event confirmations."""
        results = {}
        
        for witness in self.habitat.witnesses:
            # Query witness for event receipts
            # (simplified - actual implementation uses keri.core.eventing)
            results[witness] = self._query_witness(witness)
        
        return results
    
    def _query_witness(self, url: str) -> dict:
        """Query single witness."""
        # Implementation depends on your witness setup
        pass
```

### Pattern 3: Verifiable Credentials

```python
# src/my_keri_app/credentials.py
from keri.app import habbing, credentialing
from typing import Dict, Any

class CredentialManager:
    """Issue and verify credentials."""
    
    def __init__(self, issuer_hab: habbing.Habitat):
        self.issuer = issuer_hab
        self.registry = credentialing.Registry(hby=issuer_hab)
    
    def issue_credential(
        self,
        subject_id: str,
        claims: Dict[str, Any]
    ) -> str:
        """Issue a verifiable credential.
        
        Args:
            subject_id: Identifier of credential subject
            claims: Credential claims
            
        Returns:
            Credential ID (SAID)
        """
        credential = {
            "issuer": self.issuer.pre,
            "subject": subject_id,
            "claims": claims
        }
        
        vc = self.registry.issue(
            issuer=self.issuer.pre,
            credential=credential
        )
        
        return vc.said
    
    def verify_credential(self, credential_id: str) -> bool:
        """Verify a credential.
        
        Args:
            credential_id: Credential SAID
            
        Returns:
            True if credential is valid
        """
        return self.registry.verify(credential_id)
```

## Debugging KERI Applications

### Enable Debug Logging

```python
# Enable KERI debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# KERI uses standard Python logging
keri_logger = logging.getLogger('keri')
keri_logger.setLevel(logging.DEBUG)
```

### Inspect KERI Database

KERI uses LMDB for storage. You can inspect it:

```bash
# Install lmdb tools
pip install lmdb

# View database contents
python -c "
import lmdb
env = lmdb.open('.keri/db/myapp')
with env.begin() as txn:
    cursor = txn.cursor()
    for key, value in cursor:
        print(f'{key}: {value}')
"
```

### Common Issues

#### Issue 1: "Missing libsodium"

**Symptom**: ImportError about libsodium or nacl

**Solution**: The Nix environment should provide libsodium. Verify:

```bash
pkg-config --modversion libsodium
```

If missing, add to `flake.nix`:

```nix
systemDeps = with pkgs; [
  libsodium  # Add this
];
```

#### Issue 2: Async Tests Failing

**Symptom**: Tests hang or fail with asyncio errors

**Solution**: Ensure pytest-asyncio is configured:

```ini
# pytest.ini
[pytest]
asyncio_mode = auto  # Auto-detect async tests
```

#### Issue 3: Type Errors from KERI Libraries

**Symptom**: mypy complains about KERI imports

**Solution**: Ignore missing type stubs in `mypy.ini`:

```ini
[mypy-keri.*]
ignore_missing_imports = True
```

## Performance Considerations

### Database Performance

KERI uses LMDB, which is very fast but benefits from tuning:

```python
# Increase map size for large databases
with habbing.Habitat(
    name='myapp',
    base='.keri/db',
    **{'map_size': 1024 * 1024 * 1024}  # 1 GB
) as hab:
    pass
```

### Async Performance

Use hio's async primitives for concurrent operations:

```python
import asyncio
from hio.base import doing

async def process_events_concurrently(events):
    """Process multiple events concurrently."""
    tasks = [process_single_event(e) for e in events]
    return await asyncio.gather(*tasks)
```

### Memory Management

KERI habitats hold resources. Always use context managers:

```python
# Good: Resources cleaned up automatically
with habbing.Habitat(name='myapp') as hab:
    hab.makeInception()

# Bad: Resources may leak
hab = habbing.Habitat(name='myapp')
hab.makeInception()
# hab not closed!
```

## See Also

- [Python Development](python-development.md) - Generic Python workflow guide
- [Nix Modules Usage](nix-modules-usage.md) - Home-Manager modules overview
- [Example Template](../examples/python-nix-direnv/) - KERI-ready project template

## External Resources

- [KERI Foundation](https://keri.one/)
- [KERIpy GitHub](https://github.com/WebOfTrust/keripy)
- [KERI Whitepaper](https://github.com/SmithSamuelM/Papers/blob/master/whitepapers/KERI_WP_2.x.web.pdf)
- [hio Documentation](https://github.com/WebOfTrust/hio)
- [KERI Developer Resources](https://keri.one/developers/)
