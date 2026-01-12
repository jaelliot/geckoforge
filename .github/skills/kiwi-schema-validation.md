# KIWI NG Schema Validation Skill

## Purpose
Validate KIWI NG config.xml files against the v10.x schema to prevent build failures.

## Trigger
When editing files matching: `profile/config.xml`, `**/config.xml`

## Schema Requirements (KIWI NG v10.x)

### Required Elements

```xml
<?xml version="1.0" encoding="utf-8"?>
<image schemaversion="8.0" name="image-name">
  
  <!-- REQUIRED: description with contact -->
  <description type="system">
    <author>Author Name</author>
    <contact>email@example.com</contact>
    <specification>Image description</specification>
  </description>

  <!-- REQUIRED: preferences with type -->
  <preferences>
    <type image="iso" primary="true" flags="overlay" mediacheck="true"/>
    <version>0.1.0</version>
  </preferences>

  <!-- REQUIRED: at least one repository -->
  <repository type="rpm-md">
    <source path="http://download.opensuse.org/..."/>
  </repository>

  <!-- REQUIRED: bootstrap packages -->
  <packages type="bootstrap">
    <package name="aaa_base"/>
  </packages>

  <!-- REQUIRED: image packages -->
  <packages type="image">
    <package name="kernel-default"/>
  </packages>

</image>
```

## Common Schema Errors

### ❌ ERROR: Missing contact element
```xml
<!-- WRONG -->
<description type="system">
  <author>Jay</author>
  <specification>My image</specification>
</description>

<!-- CORRECT -->
<description type="system">
  <author>Jay</author>
  <contact>jay@example.com</contact>
  <specification>My image</specification>
</description>
```

### ❌ ERROR: Package text content instead of name attribute
```xml
<!-- WRONG (KIWI v7 syntax) -->
<package>bash</package>

<!-- CORRECT (KIWI v10+ syntax) -->
<package name="bash"/>
```

### ❌ ERROR: Using deprecated hybrid attribute
```xml
<!-- WRONG -->
<type image="iso" hybrid="true"/>

<!-- CORRECT (hybrid is default for ISO) -->
<type image="iso" primary="true" flags="overlay" mediacheck="true"/>
```

### ❌ ERROR: Using deprecated <files> element
```xml
<!-- WRONG (deprecated in KIWI v8+) -->
<files>
  <file name="/etc/config" mode="0644">source/file</file>
</files>

<!-- CORRECT: Use root/ overlay directory instead -->
<!-- Place files in: profile/root/etc/config -->
<!-- They will be copied to /etc/config in image -->
```

### ❌ ERROR: Wrong config file name
```
# WRONG file names:
profile/config.kiwi.xml  ❌
profile/kiwi.xml         ❌  
profile/image.xml        ❌

# CORRECT file names:
profile/config.xml       ✅
profile/myimage.kiwi     ✅  (ends with .kiwi)
```

## Validation Commands

```bash
# Validate schema
kiwi-ng system validate --description profile/

# Validate with verbose output
kiwi-ng --debug system validate --description profile/

# Check XML syntax only
xmllint --noout profile/config.xml
```

## Checklist Before Build

- [ ] File is named `config.xml` or `*.kiwi`
- [ ] `<description>` has `<contact>` element
- [ ] All `<package>` elements use `name="..."` attribute
- [ ] No `hybrid` attribute on `<type>` (use `mediacheck` if needed)
- [ ] No `<files>` element (use `root/` overlay directory)
- [ ] `schemaversion="8.0"` or higher
- [ ] At least one `<repository>` defined
- [ ] Bootstrap packages include: `aaa_base`, `filesystem`, `glibc`, `rpm`, `zypper`
