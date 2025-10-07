# geckoforge

Reproducible, production-grade desktop images for **openSUSE Leap** built with **KIWI NG**
(+ optional **Open Build Service** pipelines).

## Goals
- Extremely stable base (Leap) with **Btrfs + Snapper** rollbacks
- Secure defaults (AppArmor, firewalld, keep **Secure Boot**)
- Optional **NVIDIA** support via official repo (installed on first boot if HW found)
- All config tracked in Git; images are rebuildable

## Profiles
- `leap-15.6/gnome-nvidia`: GNOME desktop, NVIDIA repo preconfigured

## Build locally (Podman/Docker)
```bash
./tools/kiwi-build.sh profiles/leap-15.6/gnome-nvidia
# ISO appears in ./out/
```

## Quick test in QEMU

```bash
ISO=$(ls out/*.iso | tail -n1)
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom "$ISO"
```

## Notes

* On first boot, if an NVIDIA GPU is detected, `firstboot-nvidia.sh` installs a suitable driver.
* With Secure Boot, the installer may prompt to enroll a MOK at reboot.
