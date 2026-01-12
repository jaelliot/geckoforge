# geckoforge Anti-Pattern Prevention Skill

## Purpose
Prevent common mistakes identified in the audit that cause build failures or runtime issues.

## Critical Anti-Patterns (NEVER DO)

### 1. Wrong Config File Name

```
❌ WRONG                          ✅ CORRECT
profile/config.kiwi.xml          profile/config.xml
profile/kiwi.xml                 profile/config.xml
profile/image.kiwi.xml           profile/config.xml
```

**Why:** KIWI NG looks for `config.xml` or files ending in `.kiwi` (not `.kiwi.xml`)

---

### 2. Package Element Text Content

```xml
❌ WRONG (KIWI v7 syntax)
<packages type="image">
  <package>kernel-default</package>
  <package>bash</package>
</packages>

✅ CORRECT (KIWI v10+ syntax)
<packages type="image">
  <package name="kernel-default"/>
  <package name="bash"/>
</packages>
```

**Why:** KIWI NG v8+ requires `name` attribute

---

### 3. Missing Contact Element

```xml
❌ WRONG
<description type="system">
  <author>Jay</author>
  <specification>My image</specification>
</description>

✅ CORRECT
<description type="system">
  <author>Jay</author>
  <contact>jay@example.com</contact>
  <specification>My image</specification>
</description>
```

**Why:** `<contact>` is mandatory in KIWI NG schema

---

### 4. Using Deprecated <files> Element

```xml
❌ WRONG (deprecated in KIWI v8+)
<files>
  <file name="/etc/config" mode="0644">source</file>
</files>

✅ CORRECT (use overlay directory)
<!-- Place file at: profile/root/etc/config -->
<!-- It will be copied to /etc/config in image -->
```

**Why:** `<files>` element was removed in KIWI v8

---

### 5. Using hybrid Attribute on ISO

```xml
❌ WRONG
<type image="iso" hybrid="true"/>

✅ CORRECT
<type image="iso" primary="true" flags="overlay" mediacheck="true"/>
```

**Why:** `hybrid` is obsolete; ISOs are hybrid by default in KIWI NG

---

### 6. Docker Instead of Native KIWI on VMware

```bash
❌ WRONG (permission issues on VMware Fusion)
docker run -v $PWD/profile:/build opensuse/kiwi ...

✅ CORRECT (native installation)
sudo zypper install python3-kiwi
sudo kiwi-ng system build --description profile/ --target-dir out/
```

**Why:** Docker volume mounts have permission issues on VMware Fusion

---

### 7. File Instead of Symlink in target.wants

```bash
❌ WRONG
profile/root/etc/systemd/system/multi-user.target.wants/
└── geckoforge-firstboot.service  (regular file, copy of service)

✅ CORRECT
profile/root/etc/systemd/system/multi-user.target.wants/
└── geckoforge-firstboot.service -> ../geckoforge-firstboot.service  (symlink)
```

**Why:** systemd expects symlinks; files won't properly enable the service

---

### 8. Podman or CDI Syntax

```bash
❌ WRONG (Podman/CDI syntax)
podman run --device nvidia.com/gpu=all ...

✅ CORRECT (Docker syntax)
docker run --gpus all ...
```

**Why:** Project requires Docker only (per style canon)

---

### 9. TeX scheme-full

```nix
❌ WRONG
texlive.combined.scheme-full    # 5GB, unstable

✅ CORRECT
texlive.combined.scheme-medium  # 2GB, stable
```

**Why:** Project requires scheme-medium (per style canon)

---

### 10. Operations in Wrong Layer

```
❌ WRONG: Docker in KIWI config (Layer 1)
Docker requires user group membership, unavailable at build time

✅ CORRECT: Docker in user scripts (Layer 3)
scripts/setup-docker.sh runs after user login

---

❌ WRONG: Home-Manager in first-boot (Layer 2)
Home-Manager needs user context

✅ CORRECT: Home-Manager in user scripts (Layer 3/4)
User runs: home-manager switch --flake ~/geckoforge/home
```

---

### 11. Flatpak in config.sh (Build Time)

```bash
❌ WRONG (in config.sh - no internet during build)
flatpak remote-add --if-not-exists flathub https://...
flatpak install flathub org.mozilla.firefox

✅ CORRECT (in first-boot or user script)
# In firstboot script or user setup script:
flatpak remote-add --if-not-exists flathub https://...
```

**Why:** Build environment may not have internet access

---

### 12. Cross-Architecture Build Without boxbuild

```bash
❌ WRONG (building on ARM64 for x86_64 target)
# On Apple Silicon VM:
kiwi-ng system build ...  # Creates ARM64 ISO!

✅ CORRECT (use boxbuild for cross-arch)
kiwi-ng system boxbuild --x86_64 ...
# Or build on x86_64 host
```

**Why:** Native KIWI builds for host architecture only

---

## Quick Validation Checklist

Before building, verify:

- [ ] Config file is named `config.xml` (not `.kiwi.xml`)
- [ ] All `<package>` elements use `name="..."` attribute
- [ ] `<description>` includes `<contact>` element
- [ ] No `<files>` element (use `root/` overlay)
- [ ] No `hybrid` attribute on `<type>`
- [ ] Symlinks (not files) in `multi-user.target.wants/`
- [ ] First-boot scripts are executable (0755)
- [ ] Service files have correct permissions (0644)
- [ ] Building on matching architecture or using boxbuild

## Validation Command

```bash
# Run before every build
kiwi-ng system validate --description profile/
```
