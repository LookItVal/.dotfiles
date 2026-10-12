# Installing NixOS on QUINN-OMEN (alongside Windows + Arch)

Install-day runbook. Written to be followed from a phone while the laptop is in the installer console.

**Goal:** shrink Arch, add a NixOS partition, boot all three OSes from one systemd-boot menu.
Arch and Windows stay installed and bootable throughout.

> ⚠️ **Do NOT follow the "Partitioning and formatting" section of the NixOS manual.**
> It starts with `parted /dev/... mklabel gpt`, which wipes the whole disk (Windows and Arch included).
> Partitioning is done **only** with the commands in this file.

## Disk layout

| Partition | Before | After |
|---|---|---|
| `nvme0n1p1` 512M vfat | Windows ESP | **shared ESP**: systemd-boot + Windows Boot Manager, mounted at `/efi` |
| `nvme0n1p2–p4` | Windows (MSR, BitLocker C:, recovery) | untouched |
| `nvme0n1p5` 1G vfat | Arch `/boot` (GRUB) | **XBOOTLDR**: Arch + NixOS kernels, mounted at `/boot` (type change only, contents kept) |
| `nvme0n1p6` 32G | Arch swap | shared swap (**never `mkswap`**: Arch's fstab uses its UUID) |
| `nvme0n1p7` ext4 | Arch `/`, 650.6G | Arch `/`, **450 GiB** (228G used) |
| `nvme0n1p8` ext4 | (none) | **NixOS `/`**, ~200 GiB, label `nixos` |

Sector numbers below are specific to this disk (512-byte sectors, p7 starts at sector `634132480`).

---

## 0. Before install day

- [ ] Dotfiles pushed (`git -C ~/.dotfiles push`). This file and `bootstrap/configuration.nix` must be on GitHub.
- [ ] Backup of anything irreplaceable on Arch (`~/Documents`, `~/.ssh`, `~/.gnupg`, `lerd db:export` dumps) on an **external** drive or cloud.
- [ ] Uncommitted project work committed/pushed or in the backup.
- [ ] BitLocker recovery key saved off this laptop and visible at <https://aka.ms/myrecoverykey>.
- [ ] Network plan: ethernet or phone USB tethering is easiest; otherwise know the Wi-Fi password.
- [ ] In Windows (admin terminal), suspend BitLocker until manually resumed:
  ```
  manage-bde -protectors -disable C: -RebootCount 0
  ```
- [ ] Shut Windows down fully (hold **Shift** while clicking Shut down).

---

## 1. Boot the installer

1. Plug in the USB stick, power on, press **F9** at the HP logo, pick the USB stick.
2. You land in a root-capable shell as user `nixos`. Become root for everything below:
   ```
   sudo -i
   ```
3. If the text is tiny: `setfont ter-v32n` (skip if it errors).

## 2. Get online

Ethernet / phone tethering: should just work. Check with `ping -c3 nixos.org`.

Wi-Fi: try `nmtui` first. If that command doesn't exist:
```
systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "YOUR_SSID"
> set_network 0 psk "YOUR_PASSWORD"
> enable_network 0
> quit
ping -c3 nixos.org
```

## 3. Safety gate: confirm it's the right disk

```
lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME /dev/nvme0n1
cat /sys/block/nvme0n1/nvme0n1p7/start      # MUST print 634132480
```
Expect p1 vfat EFI System, p3 BitLocker, p5 vfat 1G, p6 swap 32G, p7 ext4 650.6G, and **no p8**.
**If anything doesn't match, stop here.**

## 4. Shrink Arch (p7) to 450 GiB

Order matters: shrink the filesystem *below* the target, cut the partition, then grow the filesystem back to fill it.

```
e2fsck -f /dev/nvme0n1p7
```
Must finish with no unfixed errors. If it reports problems it can't fix, **stop**.

```
resize2fs /dev/nvme0n1p7 440G
```
Filesystem → 440 GiB (below the 450 GiB target). Takes a few minutes.

```
parted /dev/nvme0n1 unit s resizepart 7 1577850879s
```
It warns that shrinking can cause data loss → type `Yes`.
Check: `parted /dev/nvme0n1 unit s print` shows p7 **End = 1577850879s**.

```
resize2fs /dev/nvme0n1p7
e2fsck -f /dev/nvme0n1p7
```
Grows the filesystem to fill exactly 450 GiB, then checks it again. Must be clean.

## 5. Create the NixOS partition, retype p5

```
sgdisk -n 8:1577850880:0 -t 8:8304 -c 8:nixos /dev/nvme0n1
```
p8 = all remaining space (~200 GiB), type "Linux x86-64 root".

```
sgdisk --typecode=5:bc13c2ff-59e6-4262-a352-b275fd6f7172 /dev/nvme0n1
```
p5 → XBOOTLDR. Changes the type only: filesystem, files and UUID stay the same.

```
partprobe /dev/nvme0n1
mkfs.ext4 -L nixos /dev/nvme0n1p8
lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTTYPENAME /dev/nvme0n1
```
Expect p5 shown as **Linux extended boot**, p7 **450G**, p8 **~200G ext4 `nixos`**.

## 6. Mount

```
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/efi /mnt/boot
mount /dev/nvme0n1p1 /mnt/efi       # shared ESP (Windows)
mount /dev/nvme0n1p5 /mnt/boot      # XBOOTLDR (Arch kernel lives here)
swapon /dev/nvme0n1p6               # NOT mkswap
df -h /mnt /mnt/efi /mnt/boot
```
Expect roughly `/mnt/efi` ~426M free and `/mnt/boot` ~750M free. `ls /mnt/boot` should show Arch's `vmlinuz-linux` and `initramfs-linux.img`.

## 7. Generate hardware config, fetch the bootstrap config

```
nixos-generate-config --root /mnt
curl -L https://raw.githubusercontent.com/LookItVal/.dotfiles/main/nixos/bootstrap/configuration.nix \
  -o /mnt/etc/nixos/configuration.nix
```

Check the generated hardware config:
```
grep -A3 -E 'fileSystems|swapDevices' /mnt/etc/nixos/hardware-configuration.nix
```
Must contain `fileSystems."/"` (p8), `fileSystems."/efi"` (vfat), `fileSystems."/boot"` (vfat), and a `swapDevices` entry.

Glance over the bootstrap config: `less /mnt/etc/nixos/configuration.nix`.

## 8. Install

```
nixos-install
```
Downloads and builds the system (several minutes). At the end it asks for a **root password**. Set one.

```
nixos-enter --root /mnt -c 'passwd val'
```

Before rebooting, confirm the boot entries landed where expected:
```
ls /mnt/boot/loader/entries/        # nixos-generation-1.conf and arch.conf
ls /mnt/efi/EFI/                     # Boot, HP, Microsoft, systemd (+ maybe Linux)
efibootmgr                           # "Linux Boot Manager" should be first in BootOrder
```

```
umount -R /mnt
reboot
```
Pull the USB stick when the screen goes dark.

## 9. First boot checks

- [ ] systemd-boot menu shows **NixOS**, **Arch Linux**, **Windows Boot Manager**.
- [ ] NixOS boots to a console login. Log in as `val`. (No desktop yet: expected.)
- [ ] Get online: `nmtui`.
- [ ] `bootctl status` lists both the ESP (`/efi`) and the XBOOTLDR partition (`/boot`).
- [ ] Reboot → **Arch Linux** boots normally (i3 etc.).
- [ ] Reboot → **Windows** boots. If it asks for the BitLocker recovery key, enter it.
- [ ] In Windows (admin), re-enable BitLocker: `manage-bde -protectors -enable C:`

**Hold Space** while booting if the menu doesn't show. From Linux: `systemctl reboot --boot-loader-menu=10`.

---

## If something goes wrong

| Problem | Fix |
|---|---|
| Nothing but Windows boots / no systemd-boot menu | **F9** → pick "Linux Boot Manager". Or F9 → **GRUB** still boots Arch (GRUB hasn't been removed). |
| Arch entry missing or fails to boot | Boot Arch via **F9 → GRUB**. In NixOS, check `ls /boot/loader/entries` and `bootctl list`; the paths in `arch.conf` are relative to the XBOOTLDR partition (p5). |
| Arch boots but complains about swap | Something ran `mkswap` on p6 and changed its UUID. In Arch: `blkid /dev/nvme0n1p6` and update the UUID in `/etc/fstab`. |
| `bootctl status` doesn't show XBOOTLDR | p5's type wasn't changed. Redo the `sgdisk --typecode=5:…` command in step 5, then `nixos-rebuild switch`. |
| `nixos-install` fails | Fix `/mnt/etc/nixos/configuration.nix` and re-run `nixos-install`. Partitions don't need redoing. |
| Need to redo something after rebooting | Boot the stick again, `sudo -i`, then repeat step 6 (mount, **without** mkfs) and continue from there. |

---

## After this

The base system is just a launchpad. Next steps (see `README.md` / `TODO.md`):

1. `git clone https://github.com/LookItVal/.dotfiles ~/.dotfiles`, `git switch -c nixos`
2. Copy `/etc/nixos/hardware-configuration.nix` into `hosts/internal/`
3. `git add` it (flakes ignore untracked files). `hosts/internal/default.nix` already has the same bootloader setup as the bootstrap config.
4. `nix flake check ./nixos`, fix errors (it has never been evaluated), then `sudo nixos-rebuild switch --flake ~/.dotfiles/nixos#internal`. If the result is broken, pick the previous generation in the boot menu.
5. Once all three OSes boot from systemd-boot: remove GRUB from Arch (`pacman -Rns grub os-prober`, delete `/boot/grub` + `/boot/EFI/GRUB`, `efibootmgr -B` its entry)
