# Roadmap

Each stage leaves the cluster in a state that can run for months. Don't start a stage until
the previous one has been stable for a while.

**Rules for the whole plan:** services are managed by k3s (Flux). Infrastructure (ZFS, NFS,
UPS shutdowns, backups, k3s itself) is managed by this flake.

---

## Stage 0: before anything else

- [ ] Back up `/shared` from server01 somewhere that isn't server01 (it's the only copy)
- [ ] Commit the homelab merge (`git commit` without `-a`)
- [ ] Set up sops-nix (age key on the laptop, nodes decrypt with their SSH host keys)
- [ ] Put the k3s join token in sops
- [ ] DHCP reservations for server01 (.27 and .170), node2 (.22), node3 (.249)
- [ ] Same timezone on all machines (`time.timeZone` in `modules/server`)

## Stage 1: 1 manager, 2 workers

| Machine | Role | Runs |
|---|---|---|
| server01 | manager (sqlite), NFS server | everything that runs today |
| node2 | worker | new apps, tainted until tested |
| node3 | worker | small apps, tainted until tested |

- [ ] NFS client support on the nodes (needed before any pod with an NFS volume lands there)
- [ ] Join node2 as an agent (`modules/server/k3s-agent.nix`, already written)
- [ ] Test pod on node2, then remove the onboarding taint
- [ ] Same for node3
- [ ] Optional: USB gigabit adapter for node2
- [ ] Optional: Jellyfin on node2 (HD 520: 1080p H.264/8-bit HEVC only)

**Weak spots:** server01 is still a single point of failure for both the cluster and the data.

## Stage 2: the NAS

| Machine | Role | Runs |
|---|---|---|
| server01 | manager (sqlite) | apps |
| node2, node3 | workers | apps |
| **NAS (DXP2800)** | **NixOS + ZFS mirror, NFS on .170, tainted k3s agent** | Jellyfin, torrent client (only pods allowed there) |
| UPS | NAS is the NUT primary | |

Hardware: DXP2800, 2 HDDs, 16 GB RAM, small NVMe boot drive, UPS.

- [ ] Add `hosts/nas` to the flake: ZFS mirror, `networking.hostId`, scrubs, auto snapshots,
      smartd, a cap on ZFS's RAM cache (`zfs_arc_max`)
- [ ] Alerts for failed scrubs / dying disks (ZFS's zed + email or ntfy). Without this, a
      dying disk goes unnoticed
- [ ] NFS export limited to the cluster's IPs (not the whole /24, no `no_root_squash`)
- [ ] Copy `/shared` to the NAS, stop the apps, move `.170` from server01 to the NAS, start
      the apps. The PVs don't need to change
- [ ] Off-NAS backup (restic to USB drive or Backblaze B2)
- [ ] UPS: NUT on the NAS as primary, every other node as secondary (`power.ups`), shut down
      after ~2 min on battery, NAS goes last and tells the UPS to cut power
- [ ] "Power on after AC loss" in the NAS's BIOS
- [ ] Wake-on-LAN for the laptops (Pi, or the NAS after it boots). Test that it actually
      works on each laptop
- [ ] Network switch and router on the UPS too
- [ ] Test it: pull the UPS plug and watch everything shut down and come back
- [ ] Join the NAS as an agent with a taint, move Jellyfin there with `/dev/dri`

**Weak spots:** cluster control still lives only on server01. The data no longer does.

## Stage 3: HA (first new node)

| Machine | Role | Runs |
|---|---|---|
| **OptiPlex 3070** | **manager**, PLP SSD for k3s | general apps, Immich |
| node2 | **manager**, PLP SSD replaces the HDD | apps |
| node3 | **manager**, PLP SSD, control plane only (taint off normal pods) | etcd, k3s |
| NAS | tainted agent | Jellyfin, torrent client |
| server01 | **worker** (reinstalled with NixOS, joined like node2/node3) | apps |

Hardware: OptiPlex, 3 PLP SSDs.

**Could we do HA before the OptiPlex, with server01 + node2 + node3?** Technically yes, with
3 PLP SSDs. Not worth it: server01 needs a blade-to-M.2 adapter swap in a MacBook, it can't
turn itself back on after a power cut, and you'd move the managers again when the OptiPlex
arrives. Waiting for the OptiPlex means no surgery on the MacBook ever.

node3 only has 3.7 GB, which is enough for etcd + control plane if nothing else runs there.

- [ ] Run the sync test on each new SSD before using it (target: p99 < 10 ms)
- [ ] Set up a stable API address (kube-vip virtual IP), and DHCP reservations for every machine
- [ ] Back up server01's k3s data
- [ ] Convert server01 from sqlite to embedded etcd (restart with `--cluster-init`)
- [ ] Join the OptiPlex as a server
- [ ] node2: leave the cluster, swap in the SSD, rejoin as a server
- [ ] node3: same
- [ ] Remove server01 from the cluster (it's the 4th etcd member at that point), check etcd
      has 3 healthy members
- [ ] Reinstall server01 with NixOS (`hosts/server01`), join it back as an agent
- [ ] Turn on etcd snapshots to the NAS
- [ ] Move database apps (Postgres) from NFS to local storage on SSD nodes, with `pg_dump`
      backups to the NAS
- [ ] Check every step against the k3s docs at the time (versions will have moved)

**Weak spots:** node3 is a tight manager (RAM). node2 still has a 100 Mb NIC (fine for etcd).

## Stage 4: the 6600H

| Machine | Role | Runs |
|---|---|---|
| OptiPlex | manager | general apps, Immich |
| node2 | manager | apps |
| **6600H mini PC** | **manager** (replaces node3) | Minecraft, heavy apps |
| node3 | worker again | small apps |
| server01 | worker | apps |
| NAS | tainted agent | Jellyfin, torrent client |

- [ ] Run the sync test on the mini PC's NVMe. If it fails, add a PLP drive
- [ ] Join the 6600H as a server, then move node3 back to agent (leave, rejoin)
- [ ] Minecraft pod with a memory limit (so it can't starve etcd)

**This is the end state.** Any one manager can go down and the cluster keeps running.

---

## App placement (end state)

| Where | Apps |
|---|---|
| NAS (tainted) | Jellyfin, torrent client |
| 6600H | Minecraft, Prometheus |
| OptiPlex | Immich, databases |
| anywhere | Vaultwarden, Obsidian LiveSync, Ghost, WordPress, Forgejo/Gogs, Reactive Resume, Linkwarden, Koel, ConvertX, Prowlarr, Seafile, BentoPDF, Mealie, Akaunting, Scrutiny, Radarr/Lidarr/Sonarr, Soularr, Jellyseerr, Signal CLI |
| 2 replicas on different nodes | Technitium (or keep a fallback DNS on the router) |

Notes: Prowlarr replaces Jackett. Forgejo is the more active fork of Gogs. Immich's ML can
be offloaded to a desktop with a GPU.
