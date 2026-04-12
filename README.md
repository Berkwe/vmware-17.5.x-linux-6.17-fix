# VMware Workstation 17.5.x — Linux Kernel 6.17 Fix

Tested on: KDE Neon (Ubuntu 24.04 base) | VMware Workstation 17.5.2 | Kernel 6.17.0-20-generic

## The Problem

VMware kernel modules (`vmmon` & `vmnet`) fail to compile on Linux 6.17 due to several API removals and include path issues.

## What Changed in Kernel 6.17

| Old | New | File |
|-----|-----|------|
| `del_timer_sync()` | `timer_delete_sync()` | `linux/driver.c`, `linux/hostif.c` |
| `rdmsrl_safe()` | `rdmsrq_safe()` | `linux/hostif.c` |
| `dev_base_lock` (removed) | `rcu_read_lock()` | `vmnet-only/vmnetInt.h` |
| Makefile include paths | hardcoded absolute paths | `Makefile.kernel` |

## Usage

```bash
bash vmware-kernel-fix.sh
```

Root password will be asked once for module installation.

## Notes

- Run this script after every kernel update
- Tested with VMware Workstation 17.5.2 build-23775571
- mkubecek's repo doesn't have a 6.17 branch yet — this fills the gap until it does
- Script re-extracts from VMware's own source tars so original installation stays clean

## Credits

- [mkubecek/vmware-host-modules](https://github.com/mkubecek/vmware-host-modules) — the OG patch repo this builds on
