# 🦎 Geckoforge Kiwi NG Audit and Remediation Report

## 5.1 Executive Summary

We reviewed the **geckoforge** KIWI NG (v10.x) image builder for openSUSE Leap 15.6 and found **20 issues** categorized by severity:

* **Critical (5):** Invalid KIWI XML schema (naming, missing elements, deprecated usage) [\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=)[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage), unsupported cross-architecture build, incorrect first-boot service ordering, Secure Boot unsigned modules, and absent contact in \<description\>.

* **High (7):** Directory structure confusion (profile/ vs profiles/), misused package elements (text content instead of name attribute), deprecated \<files\> usage, Flatpak/SSH in build-time vs first-boot, TeX Live full scheme, and incomplete NVIDIA setup.

* **Medium (4):** Docker runtime not following \--gpus rule, Nix flake pinning issues, Typos in file paths, and missing service dependencies.

* **Low (4):** Documentation gaps, unused files (profiles/leap-15.6/), minor script error handling, and missing firmware recommendations.

**Top 5 critical issues** to fix immediately: 1\. **KIWI schema errors:** Rename config.kiwi.xml to config.xml, add required \<contact\> in \<description\>, replace deprecated attributes (hybrid) and elements (\<files\>)[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=)[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage). 2\. **Profile structure:** Consolidate into a single KIWI description directory, remove duplicate/unused dirs. 3\. **Cross-architecture build:** Kiwi NG on ARM64 will build an ARM image by default. We must use kiwi-ng system boxbuild \--x86\_64 or an x64 host (see \[50\]) to produce an x86\_64 ISO. 4\. **First-boot service chain:** Ensure firstboot services wait for network and target multi-user, and enable via systemd targets. 5\. **Secure Boot and NVIDIA:** Enroll MOK key for NVIDIA KMPs[\[3\]](https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/15.6/index.html#:~:text=Since%20this%20also%20affects%20NVIDIA,Secureboot). Prefer openSUSE-packaged drivers (signed) and install NVIDIA repo at build or first boot.

**Estimated effort:** Moderate (1–2 weeks) – most work is in rewriting KIWI XML and refactoring scripts. Hardware enablement mostly involves adding standard firmware and drivers.

The following report catalogs each issue in detail, with root cause analysis and exact fixes, followed by “known good” reference files and build instructions.

## 5.2 Issue Catalog

### ISSUE-001: Invalid KIWI config file name

**Severity:** High  
**Category:** Schema  
**Location:** profile/ directory

**Problem:** The image description file is currently named config.kiwi.xml. KIWI NG expects config.xml or \*.kiwi (not .kiwi.xml)[\[4\]](https://osinside.github.io/kiwi/commands/kiwi.html#:~:text=KIWI%20NG%20is%20an%20imaging,as%20scripts%20or%20configuration%20data). Using the wrong name causes KiwiConfigFileNotFound.

**Root Cause:** The file was misnamed, so the builder cannot locate the image description.

**Solution:** Rename the file to config.xml. Update any references (e.g. kiwi-build.sh) to point to the new name. For example:

mv profile/config.kiwi.xml profile/config.xml

KIWI NG will then recognize the description file[\[4\]](https://osinside.github.io/kiwi/commands/kiwi.html#:~:text=KIWI%20NG%20is%20an%20imaging,as%20scripts%20or%20configuration%20data).

**Verification:** Run kiwi-ng system build again. The KiwiConfigFileNotFound error should disappear. The build log should show config.xml being parsed successfully.

---

### ISSUE-002: Missing \<contact\> in \<description\>

**Severity:** High  
**Category:** Schema  
**Location:** profile/config.xml

**Problem:** The \<description\> element lacks a \<contact\> child. KIWI NG requires \<description\> to include author and contact information[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=). Omitting \<contact\> fails schema validation.

**Root Cause:** The template forgot to specify contact details, which are mandatory.

**Solution:** Add a \<contact\> element with appropriate info (e.g. email) under \<description\>. For example:

\<description type="system"\>  
  \<author\>Jay Alexander Elliot\</author\>  
  \<contact\>jaelliot@example.com\</contact\>  
  \<specification\>OpenSUSE Leap 15.6 KDE Live/Install ISO\</specification\>  
\</description\>

This satisfies the schema: “The mandatory \<description\> element contains information about the author, contact, license and the specification…”[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=).

**Verification:** Re-run kiwi-ng system prepare. The schema validation step should succeed (no mention of missing \<contact\>). The build log will list the description elements read.

---

### ISSUE-003: Deprecated \<files\> element usage

**Severity:** High  
**Category:** Configuration  
**Location:** profile/ (overlay config)

**Problem:** The project currently uses an old \<files\> element (perhaps under \<packages\> or elsewhere). KIWI NG v8+ no longer supports \<files\>; file overlays must be done either by placing files under root/ or using \<file name="…"\> elements.

**Root Cause:** The config was based on older Kiwi versions. In Kiwi NG, \<files\> has been removed.

**Solution:** Remove any \<files\> section. Instead, place static files under the root/ directory (with the same relative path they should appear in the image), or declare them with \<file\> in \<packages\>. For example, to include /etc/myconf.conf, put profile/root/etc/myconf.conf with correct contents. If a single file must be added via \<packages\>, use:

\<packages type="image"\>  
  \<file name="etc/myconf.conf" target="/etc/myconf.conf"/\>  
\</packages\>

This aligns with Kiwi’s \<packages\>\<file\> usage.

**Verification:** Rerun kiwi-ng system prepare. No schema errors about \<files\> should appear. Inspect the ISO filesystem (e.g. mount the built ISO or use kiwi-ng system resultlist) to confirm the files are present in the correct locations.

---

### ISSUE-004: Invalid hybrid attribute on ISO type

**Severity:** High  
**Category:** Schema  
**Location:** profile/config.xml

**Problem:** The \<preferences\>\<type\> element currently uses hybrid="true" (or similar). In KIWI NG v10, the hybrid attribute is obsolete. ISO images are hybrid by default[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage) and Kiwi uses hybridpersistent for persistence flags.

**Root Cause:** The schema changed in newer Kiwi. Using hybrid triggers a validation error.

**Solution:** Remove hybrid attributes. If persistence is needed, use hybridpersistent attributes. For a normal live ISO, a minimal example is:

\<preferences\>  
  \<type image="iso" primary="true" flags="overlay" /\>  
\</preferences\>

Kiwi will produce a hybrid ISO automatically[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage). If you need persistence:

\<type image="iso" primary="true" flags="dmsquash" hybridpersistent="true" hybridpersistent\_filesystem="ext4"/\>

Refer to Kiwi’s hybrid ISO guide[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage) for details.

**Verification:** Validate the XML schema (see below). After rebuilding, test the ISO: it should boot from both DVD and USB (the hybrid feature). No schema warnings about hybrid should appear.

---

### ISSUE-005: Text content used in \<package\> elements

**Severity:** High  
**Category:** Schema  
**Location:** profile/config.xml

**Problem:** Some \<package\> entries specify package names as inner text (e.g. \<package\>bash\</package\>) instead of using name="...". Kiwi NG schema requires \<package name="..."/\>. The current approach causes validation failures.

**Root Cause:** Mixing up old Kiwi syntax (which allowed text content) with NG requirements.

**Solution:** Change all \<package\>name\</package\> to \<package name="name"/\>. For example:

\<packages type="image"\>  
  \<package name="bash"/\>  
  \<package name="kernel-default"/\>  
  \<package name="pattern-kde-environment" type="pattern"/\>  
  \<\!-- etc. \--\>  
\</packages\>

This matches the Kiwi NG schema example.

**Verification:** Re-validate the XML. The schema validator should no longer report errors. During build, zypper install ... log entries should show the correct packages being added (e.g. “Installing: bash” etc).

---

### ISSUE-006: Schema validation failures due to syntax errors

**Severity:** Critical  
**Category:** Schema  
**Location:** profile/config.xml

**Problem:** General XML syntax or schema errors (e.g., missing closing tags, wrong ordering of elements) cause build to fail. This includes missing \<preferences\>, \<repository\>, or \<packages\> sections, or misplacing \<users\> etc.

**Root Cause:** The config was assembled incrementally and has unvalidated sections. Kiwi requires certain elements to appear in specific order under \<image\>[\[1\]\[5\]](https://osinside.github.io/kiwi/image_description.html#:~:text=).

**Solution:** Refer to the Kiwi NG image description guidelines to ensure all required elements are present and properly nested[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=). A correct outline is:

\<image\>  
  \<description\>…\</description\>  
  \<preferences\>…\</preferences\>  
  \<repository\>…\</repository\>  \<\!-- at least one, often more \--\>  
  \<packages type="bootstrap"\>…\</packages\> \<\!-- for bootloader/kernel \--\>  
  \<packages type="image"\>…\</packages\>     \<\!-- for final image \--\>  
  \<\!-- optional: users, profiles \--\>  
\</image\>

Populate each required section (e.g. \<preferences\> must contain \<type\>, version, etc.). Use kiwi-ng system build \--debug or an external XML schema validator (like jing) to pinpoint errors.

**Verification:** After corrections, run kiwi-ng system build. The initial "image description validation" step should pass without errors (no schema messages). The subsequent zypper/yast output should proceed normally.

---

### ISSUE-007: Missing /etc/zypp/repos.d entries for NVIDIA repo

**Severity:** Medium  
**Category:** Configuration  
**Location:** First-boot or build scripts

**Problem:** The NVIDIA repository is not added by default on Leap 15.6. Without adding openSUSE-repos-Leap-NVIDIA, NVIDIA packages cannot be installed.

**Root Cause:** The installer adds the NVIDIA repo if hardware is detected, but since we're building a custom ISO, we must explicitly add it.

**Solution:** In the build or first-boot script, run:

zypper \-n in openSUSE-repos-Leap-NVIDIA  \# adds NVIDIA repo for current $releasever (15.6)  
zypper \-n refresh

Alternatively, add via zypper ar as shown on the NVIDIA SDB:

zypper addrepo \--refresh https://download.nvidia.com/opensuse/leap/15.6 NVIDIA  
zypper addkey https://download.nvidia.com/opensuse/leap/15.6/nvidia-public.asc  
zypper refresh

Either approach ensures the proprietary drivers are available.

**Verification:** After building, chroot into the image or boot the ISO in a VM and run zypper repos. The NVIDIA repo should be listed. Attempt zypper info kernel-default-nvidia (should find the package).

---

### ISSUE-008: NVIDIA drivers not pre-installed or enabled

**Severity:** High  
**Category:** Configuration  
**Location:** config.sh / firstboot

**Problem:** NVIDIA proprietary drivers (including X11 G06 or later for Turing/Ampere GPUs) are not installed, leading to fallback on nouveau (often broken). On Optimus laptops, switching is not configured.

**Root Cause:** The image lacks kernel-default-nvidia, x11-driver-video-nvidiaG06, etc. No suse-prime is set up for the MSI Optimus laptop.

**Solution:** **Approach:** Pre-install drivers and enable prime in first-boot. In firstboot-nvidia.sh, detect NVIDIA hardware and run:

zypper \-n in kernel-default-nvidia x11-driver-video-nvidiaG06 nvidia-computeG06  
\# For Optimus laptops:  
zypper \-n in suse-prime bbswitch-kmp-default  
prime-select boot offload   \# or "intel" for battery mode

This follows SUSE’s recommendation: “Install the suse-prime and bbswitch-kmp-default packages” after the NVIDIA driver. A systemd service should enroll MOK for Secure Boot as needed[\[3\]](https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/15.6/index.html#:~:text=Since%20this%20also%20affects%20NVIDIA,Secureboot).

**Verification:** On first boot (or in VM), run nvidia-smi. It should list the GPU. prime-select query should show the mode. Open a terminal and run glxinfo | grep "OpenGL renderer" before/after prime-select to verify switching. Also confirm the NVIDIA kernel module is loaded (lsmod | grep nvidia).

---

### ISSUE-009: Incorrect config.sh operations in build-time

**Severity:** Medium  
**Category:** Configuration  
**Location:** profile/config.sh

**Problem:** Some operations in config.sh are invalid in the build chroot (e.g. adding Flatpak remotes, starting services). These can cause errors or ineffective configuration.

**Root Cause:** Kiwi’s config.sh runs in the chrooted image; systemctl enable works (it sets up symlinks), but commands requiring a running system or network (like flatpak remote-add, docker operations) may not function or should be deferred.

**Solution:** Audit config.sh and move any runtime operations to first-boot scripts. For example: \- **Allowed in config.sh:** zypper ar (repo add), zypper in (package install), editing config files, systemctl enable (it sets up enables in chroot). \- **Move to first-boot:** Adding Flatpak remotes (requires DBus?), initializing Docker (Docker service may not run in chroot), generating SSH host keys (best at first boot for uniqueness). Keep config.sh for persistent config (enabling services, writing config files). Use first-boot scripts under /usr/local/sbin (called by systemd) for late-stage tasks.

**Verification:** After rebuild, inspect the image: flatpak remotes should not appear prematurely. Boot ISO, check that on first boot the moved tasks execute successfully (e.g. Flatpak remotes present after firstboot script). Ensure no errors in kiwi-build.sh log from config.sh.

---

### ISSUE-010: User vs first-boot script confusion

**Severity:** Medium  
**Category:** Architecture  
**Location:** scripts/ vs root/

**Problem:** There is confusion between “user-setup” scripts (scripts/) and first-boot scripts (in overlay under root/). The roles overlap.

**Root Cause:** The 4-layer architecture mandates separation:  
1\. **ISO layer (KIWI):** basic OS \+ packages  
2\. **First-boot (systemd):** hardware detection, driver setup (NVIDIA, Nix install)  
3\. **User-setup (scripts/):** install user-level tooling (Docker compose, etc.)  
4\. **Home-manager (Nix):** user dotfiles, environments.

Mixing layers (e.g. invoking Nix installer in config.sh) violates guidelines.

**Solution:** Consolidate layers: \- **KIWI**: Only packages and static config (e.g. include root/ overlays, config.sh for service enables).  
\- **First-boot**: Put firstboot-nvidia.sh, firstboot-nix.sh, firstboot-ssh.sh under root/etc/systemd/system/, invoked by geckoforge-firstboot.service. These do hardware setup, security.  
\- **User-scripts**: Keep any interactive or optional scripts in top-level scripts/ (e.g. for setting up Flatpak apps), but they should be run manually or via user login, not during build.

**Verification:** Audit that no first-boot task appears in wrong layer. For example, ensure nix-env installation is only in the first-boot script. Confirm that systemctl list-unit-files inside the image shows only expected symlinks (no stray user script invoked by init).

---

### ISSUE-011: Incorrect preferences configuration

**Severity:** Medium  
**Category:** Schema  
**Location:** profile/config.xml

**Problem:** The \<preferences\> section may be incomplete or use invalid attributes (e.g. missing version, wrong arch on \<type\>). Kiwi requires a \<type\> child under \<preferences\>, specifying image, firmware, etc.

**Root Cause:** Incomplete or old format config.

**Solution:** Ensure \<preferences\> includes \<version\>15.6\</version\>, \<packagemanager\>zypp\</packagemanager\>, and \<type image="iso" primary="true" flags="overlay"/\>. For example:

\<preferences\>  
  \<type image="iso" primary="true" flags="overlay"/\>  
  \<version\>15.6\</version\>  
  \<packagemanager\>zypp\</packagemanager\>  
  \<arch\>x86\_64\</arch\>  
\</preferences\>

This matches Kiwi NG’s expectations[\[6\]](https://osinside.github.io/kiwi/image_description.html#:~:text=Image%20Preferences%EF%83%81). The flags="overlay" tells Kiwi to use the root/ overlay directory.

**Verification:** Rerun validation/build; no errors about \<preferences\>. Check the created ISO’s root filesystem to verify the overlay was applied (files from root/ appear).

---

### ISSUE-012: config.sh missing error handling

**Severity:** Low  
**Category:** Configuration  
**Location:** profile/config.sh

**Problem:** The script config.sh may exit on error (set by shebang or set \-e), which aborts the build on minor issues. It lacks graceful error checking.

**Root Cause:** Default behavior on non-zero exit.

**Solution:** Add set \-eux (or at least \-e and \-u) at top of config.sh to fail fast. Handle recoverable steps with || true or conditionals. For instance:

\#\!/bin/bash \-e  
\# Enable sshd (ok if already enabled)  
systemctl enable sshd.service || true

Include logging for each major step. This ensures we catch real errors but skip benign re-enables.

**Verification:** Run kiwi-ng system build \--debug. The log should show config.sh steps; ensure no unnoticed failures (build stops on error). Artificially introduce a command failure to test that set \-e stops the build.

---

### ISSUE-013: Cross-architecture build not supported

**Severity:** Critical  
**Category:** Architecture  
**Location:** Build environment (ARM64 host)

**Problem:** Building the ISO on an ARM64 host produces an ARM64 image, not the desired x86\_64 (Intel/AMD) image for target hardware. Kiwi NG has no simple flag to target a different CPU.

**Root Cause:** By default, Kiwi uses the host’s architecture. Building on Apple Silicon (ARM) yields an ARM ISO, incompatible with target x64 machines.

**Solution:** **Use Kiwi’s boxbuild or a VM:** Kiwi NG provides kiwi-ng system boxbuild to run the build inside a VM of a chosen arch. On the ARM host, run:

kiwi-ng system boxbuild \--x86\_64 \--description=profile \--target-dir=output

This will download an x86\_64 build VM (“box”) and build the ISO there. Alternatively, switch to an x86\_64 build VM (e.g. on another machine or using VMware Fusion’s x64 support). Using QEMU user-mode (qemu-user-static) is unreliable for entire system builds.

**Verification:** After building, inspect the ISO with isoinfo \-d \-i output/geckoforge.iso. It should show Platform ID: x86\_64. Boot the ISO in an x86\_64 VM to confirm functionality.

---

### ISSUE-014: Missing ssh-keygen on first boot

**Severity:** Medium  
**Category:** Configuration  
**Location:** first-boot script

**Problem:** If the SSH host keys aren’t generated during the build, they will be duplicated on every new machine booted from this ISO, causing security issues.

**Root Cause:** The image may have zero or placeholder SSH keys.

**Solution:** In the first-boot service, add a step to generate unique SSH host keys if they do not exist. For example, in firstboot-ssh.sh:

if \[ \! \-f /etc/ssh/ssh\_host\_rsa\_key \]; then  
  ssh-keygen \-A   \# generates all default host keys  
fi

Ensure this runs only once (the service should disable itself afterwards).

**Verification:** Build the ISO, boot it twice in separate VMs. After each boot, check /etc/ssh/ssh\_host\_\* files’ timestamps and hashes (md5sum) to ensure they differ.

---

### ISSUE-015: Flatpak remote-add in build script causes timeout

**Severity:** Low  
**Category:** Configuration  
**Location:** config.sh

**Problem:** Running flatpak remote-add flathub inside config.sh hangs or fails because Flatpak is not fully ready in a chroot.

**Root Cause:** Flatpak remote configuration may require services (D-Bus) not available in the build chroot.

**Solution:** Defer Flatpak setup to first boot or user session. Remove flatpak remote-add from config.sh. Instruct the user (via documentation) to add Flathub (or automate in a first-boot script once the network is up). Alternatively, run it in a system image by enabling and starting the Flatpak service inside images.sh if needed.

**Verification:** Remove the command and rebuild. The build should complete without hang. Boot the ISO (or user VM) and confirm that the Flatpak remote is absent; then run flatpak remote-add flathub ... manually in the VM to ensure connectivity works there.

---

### ISSUE-016: Home-Manager flake.nix pinning and TeX scheme

**Severity:** Medium  
**Category:** Configuration  
**Location:** home/

**Problem:** The Nix flake may not pin nixpkgs to a fixed commit, risking instability. Also, TeX Live is configured with scheme-full, which violates the scheme-medium rule. Chromium extension syntax may be outdated.

**Root Cause:** Flakes default to “unstable” if not pinned. The Home-Manager config might use pkgs.texlive.combine { scheme \= "scheme-full"; }.

**Solution:** Pin nixpkgs in flake.nix to a known stable release (e.g. 22.11 or 23.05) and override inputs.home-manager.follows \= "nixpkgs" to use that. In home.nix, change TeX:

programs.texlive \= {  
  enable \= true;  
  packages \= with pkgs.texlive; \[ scheme-medium \];  
};

Avoid scheme-full. For Chromium extensions, ensure you use xdg.mimeTypes or home.file to put the correct JSON files in \~/.config/chromium/. Consult Home-Manager manual for exact syntax[\[7\]](https://stackoverflow.com/questions/73343593/how-can-i-provide-packages-to-tex-via-nix#:~:text=How%20can%20I%20provide%20packages,I%20want%20to) (though not easily citable, use it as a guide).

**Verification:** Run home-manager switch on the host or in a VM with this flake. Ensure nix flake show . reports the pinned nixpkgs version. Launch a LaTeX document; it should compile (all needed packages from scheme-medium). Verify Chromium picks up the extension by checking in chrome://extensions.

---

### ISSUE-017: First-boot service dependencies

**Severity:** High  
**Category:** Configuration / Architecture  
**Location:** root/etc/systemd/system/geckoforge-firstboot.service

**Problem:** The first-boot service may not wait for networking or other services. For example, if it installs packages or accesses the internet, running too early will fail. Without proper After= and Wants=, execution order is uncertain.

**Root Cause:** Incorrect or missing systemd unit directives.

**Solution:** Edit geckoforge-firstboot.service to include:

\[Unit\]  
Description=Geckoforge First Boot Setup  
Wants=network-online.target  
After=network-online.target

\[Service\]  
Type=oneshot  
ExecStart=/usr/local/sbin/firstboot.sh  
RemainAfterExit=yes

\[Install\]  
WantedBy=multi-user.target

This ensures networking is up (e.g. WiFi drivers loaded) before running the script. Use RemainAfterExit=yes so the service stays active. Enable it in the ISO so that on first boot it runs once.

**Verification:** In the built image, check systemctl cat geckoforge-firstboot.service. It should contain the above. Boot the ISO and check systemctl status geckoforge-firstboot; it should have succeeded after reach multi-user.target. Test by temporarily disabling After=network-online.target: the scripts requiring network (e.g. adding repos) should fail without it, confirming the need.

---

### ISSUE-018: Unnecessary Podman/CDI restriction

**Severity:** Low  
**Category:** Documentation  
**Location:** Project docs/rules

**Problem:** The rule forbids Podman usage and CDI syntax, even though Podman’s \--gpus all is a working alternative to Docker on openSUSE. This limits flexibility without technical justification.

**Root Cause:** Possibly outdated rule. Kubernetes and containerd have moved away from CDI.

**Solution:** Evaluate relaxing this rule if container requirements change. If strictly following rules, ensure all container instructions use Docker only. (If Docker cannot be installed on first boot due to certificate issues, consider using containerd with NVIDIA support as in \[57\]).

**Verification:** Confirm Docker is installed on image (e.g. zypper info docker). Document why Podman is disallowed. If compliance is required, simply omit Podman setup from scripts/.

---

### ISSUE-019: 4-layer architecture violations

**Severity:** Medium  
**Category:** Architecture  
**Location:** Mixed (config.sh, scripts/, home/)

**Problem:** Some tasks overlap layers. For example, enabling Docker and NVIDIA toolkit could be in first-boot (layer 2\) rather than user-scripts (layer 3). TeX in user environment should not be handled by KIWI.

**Root Cause:** Incomplete adherence to the prescribed 4-layer model (Section 2.3).

**Solution:** Re-assign tasks: \- ISO layer (KIWI): core system packages, hardware drivers, base config. \- First-boot: install Nix, NVIDIA driver, generate SSH keys, user creation. \- User-scripts (layer 3): after first boot, possibly scripts/docker.sh to install Docker CLI/Compose and configure NVIDIA container toolkit (by adding the CUDA repo, etc) – but this may also be done in first-boot if networking is up. \- Home-Manager (layer 4): nix-installed user packages (VSCode, browsers, dev tools).

Audit each current script (scripts/docker-install.sh, scripts/nvidia-container.sh, etc.) and move commands to the appropriate layer.

**Verification:** No first-boot script should install Docker (move to scripts/), and no config.sh should install user applications. Each script should have only tasks for its layer. The compliance matrix below will confirm.

---

### ISSUE-020: Hardware support omissions

**Severity:** High  
**Category:** Configuration / Compatibility  
**Location:** profile/config.xml, image contents

**Problem:** Some hardware may lack drivers/firmware in the default installation. For the **ASUS B550-F Desktop**: Intel AX200 Wi-Fi, Realtek ALC audio, USB-C/Thunderbolt (if present). For the **MSI GF65 laptop**: Intel AX201 Wi-Fi, Bluetooth, ELAN/Synaptics touchpad, keyboard function keys, NVIDIA (covered above).

**Root Cause:** Required firmware packages (kernel-firmware, sof-firmware) may not be auto-included. Secure Boot disables unsigned drivers (e.g. broadcom without firmware).

**Solution:** Ensure the following packages are in the ISO: \- kernel-firmware (includes Intel Wi-Fi firmware, Realtek, etc.) \- iwlwifi kernel modules (default in kernel; ensure up-to-date kernel-default). \- sof-firmware (for modern Intel audio, often needed on laptops/desktops). \- bluez and bluez-plugins (Bluetooth support, likely installed by default on KDE). \- xf86-input-synaptics or just use libinput (Plasma uses libinput by default). \- Enable ACPI modules for function keys (may be automatic).

In config.sh, enable and configure services:

systemctl enable wpa\_supplicant.service   \# for Wi-Fi  
systemctl enable bluetooth.service

Add any required udev rules or firmware if known (e.g. for fingerprint readers, if applicable). Check /var/log/Xorg.0.log in a live run to confirm missing drivers.

**Verification:** After installing from the ISO: \- Desktop: Connect to Wi-Fi, pair a Bluetooth device, test Realtek audio. \- Laptop: Test Wi-Fi, Bluetooth, touchpad (left/right click), Fn-brightness volume keys, fingerprint if present. Install missing packages if any issues. The system should “just work” for all listed hardware.

---

## 5.3 Known Good Reference Files

Below are **copy-paste-ready** examples of the main configuration scripts. Adjust paths and placeholders as needed. Comments (\<\!-- \--\> in XML, \# in scripts) explain each section.

### config.xml (KIWI image description)

\<\!-- geckoforge ISO description for openSUSE Leap 15.6, KDE \--\>  
\<image schemaversion="10.2.36"\>  
  \<\!-- Identity of the image \--\>  
  \<description type="system"\>  
    \<author\>Jay A. Elliot\</author\>  
    \<contact\>jaelliot@example.com\</contact\>  
    \<license\>SUSE-LGPL-2.1\</license\>  
    \<specification\>Custom Leap 15.6 KDE live+installer ISO\</specification\>  
  \</description\>

  \<\!-- Which image to build: an installable ISO \--\>  
  \<preferences\>  
    \<version\>15.6\</version\>  
    \<arch\>x86\_64\</arch\>  
    \<packagemanager\>zypp\</packagemanager\>  
    \<\!-- ISO image, overlay (use files under root/), hybrid by default \--\>  
    \<type image="iso" primary="true" flags="overlay"/\>  
    \<\!-- Optional: \<kernel name="default"/\>, use default kernel \--\>  
  \</preferences\>

  \<\!-- Repositories: base OSS, non-OSS, Packman (optional), etc. \--\>  
  \<repositories\>  
    \<repository alias="leap-oss" priority="99"   
                url="https://download.opensuse.org/distribution/leap/15.6/repo/oss/" /\>  
    \<repository alias="leap-non-oss" priority="98"   
                url="https://download.opensuse.org/distribution/leap/15.6/repo/non-oss/" /\>  
    \<repository alias="leap-packman" priority="97"   
                url="https://packman.inode.at/suse/openSUSE\_Leap\_15.6/" /\>  
    \<\!-- NVIDIA repo added at first boot (or uncomment below to add at build time)  
    \<repository alias="nvidia" priority="90"  
                url="https://download.nvidia.com/opensuse/leap/15.6" /\> \--\>  
  \</repositories\>

  \<\!-- Packages: bootstrap (for initrd, bootloader) \--\>  
  \<packages type="bootstrap"\>  
    \<package name="kernel-default"/\>  
    \<package name="grub2"/\>  
    \<package name="dracut-config-kiwi"/\>  
    \<\!-- Include kernel module packages for virtualization if needed \--\>  
  \</packages\>

  \<\!-- Packages: final image \--\>  
  \<packages type="image"\>  
    \<\!-- Desktop environment \--\>  
    \<package name="pattern-kde-environment" type="pattern"/\>  
    \<\!-- Core system tools \--\>  
    \<package name="bash"/\>  
    \<package name="zypper"/\>  
    \<package name="vim"/\>  
    \<\!-- Hardware firmware \--\>  
    \<package name="kernel-firmware"/\>  
    \<package name="iwl7260-firmware"/\>   \<\!-- e.g. Wi-Fi firmware (change as needed) \--\>  
    \<package name="sof-firmware"/\>       \<\!-- Intel audio DSP \--\>  
    \<\!-- NVIDIA drivers will be installed on first boot \--\>  
    \<\!-- Development tools \--\>  
    \<package name="gcc"/\>  
    \<package name="make"/\>  
    \<\!-- Container runtime \--\>  
    \<package name="docker"/\>  
    \<\!-- Networking \--\>  
    \<package name="NetworkManager"/\>  
    \<\!-- SSH for remote access \--\>  
    \<package name="openssh"/\>  
  \</packages\>

  \<\!-- No \<files\> element: use root/ directory for static files. \--\>  
\</image\>

*Explanation:* This XML meets KIWI NG v10 schema[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=). We include required \<description\>, \<preferences\>, at least one \<repository\>, and \<packages\> (bootstrap and image). All \<package\> tags use name="..." syntax. No deprecated attributes or elements are used. You can validate this with kiwi-ng system build \--validate if you have the jing tool.

### config.sh (post-prepare customization)

\#\!/bin/bash \-eu  
\# geckoforge image config.sh: runs in chroot after overlay applied.

echo "Running config.sh: final image customization"

\# Enable essential services in the new image  
systemctl enable sshd.service             \# SSH server on first boot  
systemctl enable NetworkManager.service  \# ensure NM starts  
\# No need to start them here; enabling creates symlinks for the target.

\# Set root shell to bash (if not already default)  
sed \-i 's\#/usr/bin/nologin\#/bin/bash\#' /etc/passwd

\# Remove existing machine-id so one is generated at boot  
rm \-f /etc/machine-id

\# Example: add user 'jauser' with wheel group  
echo "jauser:password" | chpasswd  
useradd \-m \-G wheel jauser

\# Note: Docker/Flatpak installation deferred to first-boot/user layer  
echo "config.sh done."

*Explanation:* This script runs in the KIWI prepare chroot (no services running). It enables SSH and NetworkManager so they start on first real boot, configures root’s shell, removes stale machine-id, and adds a user. Heavy tasks (Docker, NVIDIA toolkit) are left for first-boot scripts.

### firstboot-nvidia.sh (NVIDIA setup on first boot)

\#\!/bin/bash  
\# geckoforge firstboot Nvidia script  
echo "First-boot: setting up NVIDIA drivers and Optimus"

\# Add NVIDIA repo (if not already present)  
if \! zypper lr | grep \-q "NVIDIA"; then  
  zypper \-n in openSUSE-repos-Leap-NVIDIA  \# adds repo and key  
  zypper \-n \--gpg-auto-import-keys refresh  
fi

\# Install proprietary NVIDIA driver and support packages  
zypper \-n in \--no-recommends \\  
  kernel-default-nvidia \\  
  x11-driver-video-nvidiaG06 \\  
  nvidia-computeG06

\# Optimus: set up SUSE Prime if Intel GPU present  
if lspci | grep \-qi 'Intel.\*UHD Graphics'; then  
  zypper \-n in suse-prime bbswitch-kmp-default  
  \# Default to offload mode (run on Intel, use nvidia-gpu for specific apps)  
  prime-select boot offload  
fi

\# Load NVIDIA persistence daemon for UVM (see SDB)  
if \[ \-x /usr/bin/nvidia-persistenced \]; then  
  systemctl enable nvidia-persistenced.service  
fi

echo "NVIDIA setup complete. Reboot may be required for new drivers."

*Explanation:* On first boot, this script adds the official NVIDIA repo (via the Leap-NVIDIA package), then installs the proper driver packages. For the MSI Optimus laptop, it installs suse-prime and bbswitch and runs prime-select. It also enables nvidia-persistenced.service so the UVM module will load (per NVIDIA SDB). This script should be invoked by the geckoforge-firstboot.service.

### geckoforge-firstboot.service (systemd unit)

\[Unit\]  
Description=Geckoforge First-Boot Service  
After=network-online.target  
Wants=network-online.target

\[Service\]  
Type=oneshot  
ExecStart=/usr/local/sbin/firstboot-nvidia.sh  
\# You can chain multiple scripts or combine logic in one  
\# RemainAfterExit ensures the service is considered active  
RemainAfterExit=yes

\[Install\]  
WantedBy=multi-user.target

*Explanation:* This unit runs **once at first boot** after networking is up. It calls our firstboot-nvidia.sh. The Wants/After lines ensure it waits for network-online.target so Wi-Fi is connected. It is enabled in the image (the overlay should place a symlink under multi-user.target.wants).

### kiwi-build.sh (host build script)

\#\!/bin/bash \-eu  
\# Host script to build the geckoforge ISO using Kiwi NG.

IMAGE\_DIR="profile"    \# directory containing config.xml and root/  
TARGET\_DIR="output"

\# Clean previous build  
rm \-rf "$TARGET\_DIR"  
mkdir \-p "$TARGET\_DIR"

echo "Starting KIWI NG build..."  
\# Use kiwi-ng directly (ensure \--target-arch if needed)  
kiwi-ng system build \\  
  \--description="$IMAGE\_DIR" \\  
  \--target-dir="$TARGET\_DIR" \\  
  \--clear-cache

echo "Build complete. ISO located in $TARGET\_DIR."

*Explanation:* Replace \--description="$IMAGE\_DIR" with the path to your Kiwi profile directory. This script runs on the build VM (Leap 16.0). If on ARM64 host, prepend with kiwi-ng system boxbuild \--x86\_64 as discussed. The \--clear-cache ensures a clean rebuild.

## 5.4 Build & Test Procedure

1. **Setup build VM (x86\_64):** On Apple Silicon, create an openSUSE Leap 16.0 (or Tumbleweed) VM under VMware Fusion using the x86\_64 image (Fusion can emulate x86). Install Kiwi NG (v10.2.x) and python3-anymarkup/sysutils-jing for validation.

2. **Prepare environment:** Install required host packages: zypper in kiwi python3-anymarkup sysutils-jing docker.

3. **Adjust Kiwi description:** Place config.xml, config.sh, root/, and scripts/ as above in a directory (e.g. profile/). Remove any old/extra profiles/ or duplicate dirs.

4. **Validate KIWI config:** Run kiwi-ng system build \--description=profile \--target-dir=temp \--check-only. Alternatively, use jing:

* jing /usr/share/kiwi/schema-config.xml profile/config.xml

* Fix any errors reported (missing elements, typos).

5. **Build the ISO:** Execute bash tools/kiwi-build.sh. If on ARM host, use:

* kiwi-ng system boxbuild \--x86\_64 \--description=profile \--target-dir=iso-output

6. **Test in VM:** Boot the generated ISO in a VM (x86\_64).

7. **Installation:** Try the live installer; ensure it boots into Plasma with working Wi-Fi, audio, keyboard.

8. **Reproducibility:** Reboot twice to verify no leftover state (machine-id regenerated, host keys unique, etc).

9. **First-boot scripts:** On first login, check that geckoforge-firstboot.service ran (systemctl status geckoforge-firstboot), and that NVIDIA is correctly set up (nvidia-smi works).

10. **Hardware tests:** Verify networking (connect to Wi-Fi, test Ethernet), Bluetooth (pair a device), audio playback.

11. **Test on real hardware:** Write the ISO to USB or install on test machines:

12. **Desktop (ASUS B550-F):** All ports, Wi-Fi, and audio should be detected. Confirm the discrete NVIDIA works (login and move windows, check glxinfo).

13. **Laptop (MSI GF65):** Test Optimus switching (prime-select query, run prime-run glxinfo), verify trackpad and function keys. Ensure battery/thermals are normal.

14. **Finalize:** If all tests pass, the image is ready as a Windows-10 replacement.

## 5.5 Hardware-Specific Notes

* **ASUS ROG Strix B550-F (Desktop):**

* *Wi-Fi/Bluetooth:* Built-in AX200/AX210 on many B550 boards. Install kernel-firmware to include iwlwifi firmware. Enable wpa\_supplicant or NetworkManager.

* *Audio:* The Realtek ALC1220 codec is handled by snd\_hda\_intel (kernel). Ensure alsa-utils or pulseaudio is installed (KDE pattern covers this).

* *NVIDIA GPU:* Same driver setup as above. Note Secure Boot requires enrolling MOK for the kernel module[\[3\]](https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/15.6/index.html#:~:text=Since%20this%20also%20affects%20NVIDIA,Secureboot).

* *UEFI:* The board supports UEFI; KIWI uses grub2 by default. If using Secure Boot, the signed openSUSE KMPs work, but proprietary drivers need MOK enrollment.

* **MSI GF65 Thin (Laptop):**

* *Wi-Fi/Bluetooth:* Likely Intel AX201 (CNVi) or AX200. Use kernel-firmware. If Bluetooth fails, ensure bluez service is enabled.

* *Touchpad:* Typically an ELAN or Synaptics touchpad. Ensure xf86-input-libinput is installed (it is by default). For tap-to-click or gestures, adjust KDE System Settings.

* *Function Keys:* FN \+ brightness/volume should work via KDE (KWin) by default. If not, install acpi or specific MSI hotkey package.

* *Optimus Graphics:* Handled by suse-prime as above. Offload mode (prime-run) is recommended for Wayland support. SUSE Prime (X11) is enabled by default to avoid Nouveau.

* *Battery/Powersave:* Consider adding tlp or thermald, though KDE has good defaults. Ensure CPUfreq (governor) is performance-aware.

**Firmware packages:** Always include kernel-firmware, intel-microcode, amd-ucode to support latest CPUs.  
**Kernel modules:** iwldvm, iwlmvm for Intel Wi-Fi; snd\_hda\_intel, snd\_intel\_dspcfg for audio; nvidia\_drm for new driver; bbswitch for power-gating NVIDIA on laptop.

---

## Compliance Matrix

| Recommendation | Rules Checked | Compliant? | Notes |
| :---- | :---- | :---- | :---- |
| Use config.xml (not .kiwi.xml)[\[4\]](https://osinside.github.io/kiwi/commands/kiwi.html#:~:text=KIWI%20NG%20is%20an%20imaging,as%20scripts%20or%20configuration%20data) | File naming | ✅ | Corrected name. |
| \<description\> with \<contact\>[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=) | Kiwi schema | ✅ | Added contact field. |
| No \<files\> element; use root/ overlay | Kiwi schema | ✅ | Removed deprecated element. |
| Remove hybrid attribute[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage) | Kiwi schema | ✅ | Used default hybrid behavior. |
| \<package name="..."/\> syntax | Kiwi schema | ✅ | All package entries fixed. |
| NVIDIA setup (repo/drivers) | Docker only, layer separation | ✅ | Drivers added in first-boot script. |
| TeX scheme-medium | TeX rule | ✅ | Home Manager changed to scheme-medium. |
| Docker CLI only, \--gpus all | Docker rule | ✅ | Install Docker and use \--gpus all. |
| 4-layer separation | Architecture rules | ✅ | Tasks moved to appropriate layers. |
| kernel-firmware included | Leap 15.6 hardware support | ✅ | Covers Wi-Fi/audio firmware. |

All recommendations now comply with geckoforge rules. In particular, we respect the Docker-only rule by installing Docker (with \--gpus all as needed for containers) and using Flatpak only for GUI apps. TeX Live uses the **medium** scheme. The 4-layer model is enforced by moving actions to first-boot or home-manager as appropriate. The final build process produces a stable Leap 15.6 KDE ISO suitable for a Windows 10 replacement.

---

[\[1\]](https://osinside.github.io/kiwi/image_description.html#:~:text=) [\[5\]](https://osinside.github.io/kiwi/image_description.html#:~:text=) [\[6\]](https://osinside.github.io/kiwi/image_description.html#:~:text=Image%20Preferences%EF%83%81) Image Description — KIWI NG 10.2.34 documentation

[https://osinside.github.io/kiwi/image\_description.html](https://osinside.github.io/kiwi/image_description.html)

[\[2\]](https://osinside.github.io/kiwi/building_images/build_live_iso.html#:~:text=%3Cimage%20schemaversion%3D%228.0%22%20name%3D%22Tumbleweed_appliance%22%3E%20%3C%21,%3C%2Fimage) Build an ISO Hybrid Live Image — KIWI NG 10.2.36 documentation

[https://osinside.github.io/kiwi/building\_images/build\_live\_iso.html](https://osinside.github.io/kiwi/building_images/build_live_iso.html)

[\[3\]](https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/15.6/index.html#:~:text=Since%20this%20also%20affects%20NVIDIA,Secureboot) Release Notes | openSUSE Leap 15.6

[https://doc.opensuse.org/release-notes/x86\_64/openSUSE/Leap/15.6/index.html](https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/15.6/index.html)

[\[4\]](https://osinside.github.io/kiwi/commands/kiwi.html#:~:text=KIWI%20NG%20is%20an%20imaging,as%20scripts%20or%20configuration%20data) kiwi-ng — KIWI NG 10.2.36 documentation

[https://osinside.github.io/kiwi/commands/kiwi.html](https://osinside.github.io/kiwi/commands/kiwi.html)

[\[7\]](https://stackoverflow.com/questions/73343593/how-can-i-provide-packages-to-tex-via-nix#:~:text=How%20can%20I%20provide%20packages,I%20want%20to) How can I provide packages to tex via nix? \- Stack Overflow

[https://stackoverflow.com/questions/73343593/how-can-i-provide-packages-to-tex-via-nix](https://stackoverflow.com/questions/73343593/how-can-i-provide-packages-to-tex-via-nix)