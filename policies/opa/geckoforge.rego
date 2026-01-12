# @file policies/opa/geckoforge.rego
# @description Open Policy Agent rules for geckoforge compliance
# @update-policy Update when new anti-patterns are identified or audit issues change
#
# Based on: docs/research/Geckoforge-Kiwi-NG-Audit-and-Remediation-Report.md
# Issues covered: ISSUE-001 through ISSUE-020

package geckoforge

import future.keywords.in
import future.keywords.contains
import future.keywords.if

# =============================================================================
# CRITICAL VIOLATIONS (Block commits)
# =============================================================================

# ISSUE-001: Invalid KIWI config file name
violation_config_file_name contains msg if {
    input.files[_] == "profile/config.kiwi.xml"
    msg := "CRITICAL [ISSUE-001]: Config file must be named 'config.xml', not 'config.kiwi.xml'"
}

# ISSUE-005: Text content in package elements (wrong syntax)
violation_package_syntax contains msg if {
    some file in input.kiwi_files
    line := input.file_contents[file][_]
    regex.match(`<package>[^<]+</package>`, line)
    msg := sprintf("CRITICAL [ISSUE-005]: Use <package name=\"...\"/> not <package>text</package> in %s", [file])
}

# ISSUE-002: Missing contact in description
violation_missing_contact contains msg if {
    some file in input.kiwi_files
    content := concat("\n", input.file_contents[file])
    contains(content, "<description")
    not contains(content, "<contact>")
    msg := sprintf("CRITICAL [ISSUE-002]: Missing <contact> element in <description> in %s", [file])
}

# ISSUE-003: Deprecated <files> element
violation_deprecated_files contains msg if {
    some file in input.kiwi_files
    line := input.file_contents[file][_]
    contains(line, "<files>")
    msg := sprintf("CRITICAL [ISSUE-003]: Deprecated <files> element found in %s. Use root/ overlay instead", [file])
}

# ISSUE-004: Deprecated hybrid attribute
violation_hybrid_attribute contains msg if {
    some file in input.kiwi_files
    line := input.file_contents[file][_]
    regex.match(`hybrid\s*=\s*["']`, line)
    not contains(line, "hybridpersistent")
    msg := sprintf("CRITICAL [ISSUE-004]: Deprecated 'hybrid' attribute in %s. ISOs are hybrid by default", [file])
}

# =============================================================================
# HIGH SEVERITY VIOLATIONS
# =============================================================================

# Container runtime: Podman usage (Docker only)
violation_podman_usage contains msg if {
    some file in input.script_files
    line := input.file_contents[file][_]
    contains(line, "podman")
    not contains(line, "remove")
    not contains(line, "rm ")
    not contains(line, "detected")
    not contains(line, "#")
    msg := sprintf("HIGH: Podman usage detected in %s. Use Docker instead", [file])
}

# Container runtime: Podman GPU syntax
violation_podman_gpu_syntax contains msg if {
    some file in input.all_files
    line := input.file_contents[file][_]
    contains(line, "--device nvidia.com/gpu")
    msg := sprintf("HIGH: Podman GPU syntax in %s. Use '--gpus all' for Docker", [file])
}

# TeX Live: scheme-full usage
violation_tex_scheme_full contains msg if {
    some file in input.nix_files
    line := input.file_contents[file][_]
    contains(line, "scheme-full")
    not contains(line, "#")
    not contains(line, "NOT")
    msg := sprintf("HIGH: TeX scheme-full in %s. Use scheme-medium (2GB, stable)", [file])
}

# ISSUE-008: NVIDIA drivers - check for unsigned
violation_nvidia_unsigned contains msg if {
    some file in input.kiwi_files
    content := concat("\n", input.file_contents[file])
    contains(content, "nvidia-driver")
    not contains(content, "nvidia-open-driver-G06-signed")
    not contains(content, "nvidia-video-G06")
    msg := sprintf("HIGH [ISSUE-008]: Use signed NVIDIA drivers for Secure Boot in %s", [file])
}

# =============================================================================
# MEDIUM SEVERITY VIOLATIONS
# =============================================================================

# Wrong package manager commands
violation_wrong_package_manager contains msg if {
    some file in input.script_files
    line := input.file_contents[file][_]
    regex.match(`(apt-get|apt install|dnf install|pacman -S)`, line)
    not startswith(trim_space(line), "#")
    msg := sprintf("MEDIUM: Non-openSUSE package manager in %s. Use zypper", [file])
}

# Systemd service without proper ordering
violation_service_ordering contains msg if {
    some file in input.service_files
    content := concat("\n", input.file_contents[file])
    contains(content, "[Service]")
    contains(content, "network")
    not contains(content, "After=")
    msg := sprintf("MEDIUM [ISSUE-011]: Service %s accesses network but lacks After= ordering", [file])
}

# Files in multi-user.target.wants that aren't symlinks
violation_target_wants_files contains msg if {
    some file in input.files
    contains(file, "multi-user.target.wants/")
    endswith(file, ".service")
    input.file_types[file] == "file"
    msg := sprintf("MEDIUM [ISSUE-012]: %s should be a symlink, not a file", [file])
}

# =============================================================================
# LOW SEVERITY WARNINGS
# =============================================================================

# Missing firmware packages for laptops
warning_missing_firmware contains msg if {
    some file in input.kiwi_files
    content := concat("\n", input.file_contents[file])
    not contains(content, "kernel-firmware")
    msg := sprintf("LOW [ISSUE-019]: Consider adding kernel-firmware packages for laptop support in %s", [file])
}

# =============================================================================
# POLICY DECISIONS
# =============================================================================

# Collect all violations
violations := violation_config_file_name | 
              violation_package_syntax | 
              violation_missing_contact | 
              violation_deprecated_files |
              violation_hybrid_attribute |
              violation_podman_usage |
              violation_podman_gpu_syntax |
              violation_tex_scheme_full |
              violation_nvidia_unsigned |
              violation_wrong_package_manager |
              violation_service_ordering |
              violation_target_wants_files

# Collect all warnings
warnings := warning_missing_firmware

# Main decision: deny if any violations exist
deny[msg] {
    some msg in violations
}

# Advisory warnings (don't block, just inform)
warn[msg] {
    some msg in warnings
}

# Summary for reporting
summary := {
    "total_violations": count(violations),
    "total_warnings": count(warnings),
    "passed": count(violations) == 0
}
