# Current state (measured 2026-10-31 to 2026-11-03)

## Machines

| | server01 | node2 | node3 |
|---|---|---|---|
| Hardware | MacBook Pro Retina 15" mid-2012 (`MacBookPro10,1`) | HP Pavilion laptop (2016) | HP laptop |
| OS | AlmaLinux 8.10 | NixOS 26.05 (this flake) | NixOS 26.05 (this flake) |
| Role | k3s server (only node), NFS server | not in cluster yet | not in cluster yet |
| CPU | i7-3615QM, 4C/8T | i7-6500U, 2C/4T | i3-3110M, 2C/4T |
| RAM | 7.7 GB (soldered) | 11.6 GB | 3.7 GB |
| Disk | OWC Aura Pro 480 GB SATA SSD (SandForce, Apple blade connector) | HGST 1 TB 5400rpm HDD | HGST 500 GB 5400rpm HDD |
| Network | 1 Gb (USB/Thunderbolt adapter, no built-in port) | **100 Mb max (NIC limit)** | 1 Gb |
| GPU / video | HD 4000 (H.264 only), GT 650M (unusable) | HD 520 (H.264, 8-bit HEVC), 940MX (no encoder) | HD 4000 (H.264 only) |
| IP (DHCP) | 192.168.86.27, plus .170 for NFS | 192.168.86.22 | 192.168.86.249 |
| Timezone | EST | CST | CST |

## Cluster

- k3s v1.34.5+k3s1, single server, sqlite datastore (not etcd).
- Flux, external-secrets (Infisical), Tailscale operator, cloudflared.
- `/var` on server01 is a 10 GB volume at 73%: k3s and images live there.

## Storage

server01 exports `/shared` over NFS on **192.168.86.170**:
`/shared 192.168.86.0/24(rw,sync,no_subtree_check,no_root_squash)`

| PV | Size | Path | Used by |
|---|---|---|---|
| nfs-nabu-postgres-pv | 100Gi | /shared/nabu/postgres | nabu |
| nfs-nabu-obsidian-public-pv | 100Gi | /shared/obsidian/public | nabu |
| nfs-nabu-obsidian-private-pv | 20Gi | /shared/obsidian/private | nabu |
| nfs-nabu-beta-postgres-pv | 10Gi | /shared/nabu-beta/postgres | nabu-beta |
| nfs-obsidian-pv | 10Gi | /shared/obsidian/vault01 | obsidian |

Only 2.3 GB actually used. **This is the only copy.** PVs can't change their NFS server
address, so the NAS should take over `.170` when it replaces server01.

## Disk tests

etcd wants the 99th percentile of synced writes under **10 ms**. None of them pass.

| Synced write (ms, p50 / p99) | server01 | node2 | node3 |
|---|---|---|---|
| Preallocated file (etcd-like) | 50 / 70 | 37 / 100 | 33 / 103 |
| Overwrite (best case) | 19 / 27 | 11 / 13 | 11 / 67 |

| Throughput (1 GiB, O_DIRECT) | server01 | node2 | node3 |
|---|---|---|---|
| Sequential write | 244 MB/s | 97 MB/s | 94 MB/s |
| Sequential read | 391 MB/s | 102 MB/s | 100 MB/s |
| Random 4K read | 3,871 IOPS, 0.23 ms | 99 IOPS, 10 ms | 112 IOPS, 8.8 ms |

server01's SSD (SMART, 2026-10-31): PASSED, 94% life left, 0 bad blocks, ~54 TiB written,
~24k hours. But **21,123 power cycles and 559 unexpected power losses**: if those numbers
keep climbing without reboots, the drive is dropping out. Check with:
`sudo smartctl -A /dev/sda | grep -E 'Power_Cycle|Power_Loss'`

## Network

Ping between all three: 0.3 to 0.9 ms. TCP to server01: node3 ~850 Mb/s, node2 ~94 Mb/s.
