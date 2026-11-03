# Hardware plan

Prices are rough, from listings in Nov 2026. Used enterprise parts are from eBay.

## Shopping list

| Item | For | Stage | ~Price |
|---|---|---|---|
| UGREEN DXP2800 | NAS | 2 | |
| 2x Seagate IronWolf 4 TB (CMR, 5400 rpm, new, Micro Center) | NAS, ZFS mirror (~3.2 TB usable at 80%) | 2 | $190 each |
| 16 GB DDR5 SO-DIMM | NAS (replaces the 8 GB stick) | 2 | |
| Small NVMe | NAS boot drive | 2 | |
| CyberPower CP1000PFCLCD UPS | everything, NUT shutdowns | 2 | $180 ($140 refurb) |
| Dell OptiPlex 3070 SFF, i5-9500, 16 GB | manager #1 | 3 | $180 |
| 2x Intel S3500/S3510 120 GB (2.5" SATA, PLP) | etcd disks for OptiPlex and node2 | 3 | $20-30 each |
| Intel S3500/S3510 120 GB | etcd disk for node3 | 3 | $20-30 |
| Ryzen 6600H mini PC, 24 GB | manager, Minecraft, heavy apps | 4 | |
| Switch with enough ports (2.5 Gb nice to have) | | when needed | $20-100 |
| USB 3 gigabit adapter | node2 (NIC is 100 Mb) | any | $15 |
| Off-NAS backup: Whisper's spare 2 TB drive (after the desktop test), or Backblaze B2 | backup of irreplaceable data | 2 | $0 |

Not buying anymore: SSD for server01. Its Retina MacBook takes a proprietary blade, needs an
M.2 adapter (Intel S3520 M.2 150 GB + A1398 adapter, ~$45-70), and it can't power itself back
on after an outage. That rules it out as a manager, not as a worker: it stays in the cluster
as a worker on its current drive.

## Rules for buying parts

- **etcd disks need power-loss protection (PLP).** Consumer SSDs often take several ms per
  synced write; PLP drives take ~0.1 ms. Datasheet MB/s numbers don't tell you this.
- **Test every new drive** with the same sync test before it holds etcd.
- **Check SMART** on arrival for used drives (health, hours, writes).
- **NAS HDDs must be CMR.** SMR drives can take days (or fail) to rebuild a ZFS mirror.
- **Growing the NAS:** replace the mirror's disks one at a time with bigger ones (e.g. 12 TB
  Ultrastar HC520, SATA part `HUH721212ALE6xx`/`ALN6xx`, not SAS `AL5xxx`, ~$300-320 refurb).
  The pool grows when both are replaced, and the old 4 TBs become backup drives.
- **ZFS datasets with quotas** for photos / documents / media, so movies can't fill the disk.
- **UPS must be (pure) sine wave.** Business desktop PSUs can reject simulated sine.
- **Jellyfin needs Intel 7th gen+ or AMD Ryzen 4000+** for 10-bit HEVC and HDR tone mapping.

## Why this shape

- 3 managers is the minimum for HA. 2 is worse than 1 (losing either stops the cluster).
- Gigabit isn't needed for etcd (latency matters, not bandwidth), but it is for apps.
- The NAS's N100 has the best video engine of everything (10-bit HEVC, AV1 decode), so
  Jellyfin runs there, as a k3s pod pinned to the NAS.
- One modern node covers the whole app list. The second (6600H) is for Minecraft and headroom.

## Hardware notes

- **OptiPlex 3070:** budget line, probably no Intel AMT, NIC may be Realtek. UHD 630 handles
  10-bit HEVC and HDR tone mapping. Low-profile PCIe slot.
- **DXP2800:** Intel N100, 8 GB DDR5 (1 slot, 16 GB official max), no ECC, 2 SATA bays,
  2 NVMe slots. Running another OS reportedly doesn't void the warranty (check).
- **UPS:** NUT's `usbhid-ups` driver. Battery lasts 3-5 years, replacements ~$30-60.
- **NAS read cache (NVMe/L2ARC):** not worth it. Movies are read once, sequentially, and
  one HDD outruns several 4K streams.
- **Movies:** prefer 1080p HEVC (2-5 GB) over 4K remuxes (40-80 GB) while on 4 TB.

## Considered and passed on

| Machine | Why not |
|---|---|
| HP t630 thin client | AMD GX-420GI: no 10-bit HEVC, weak CPU. OK as a tiny low-power node, not for video |
| Lenovo M725s (Ryzen 5 PRO 2400G) | Weakest video encoder generation (VCN1), 8 GB |
| Dell Inspiron 3670 (i3-8100/9100) | Good video, but only 4 threads |
| Dell OptiPlex 7060 (i5-8500) | Good, the 3070 is the same thing cheaper |
| HP EliteDesk 705 G4 (2400GE) | Weak encoder, Mini has no PCIe slot |
| HP ProDesk 600 G5 (i5-9500, 32 GB) | Good, about the same as the OptiPlex 3070 |
| HP EliteDesk 805 G6 (4650GE, 6C/12T) | Strong option; a good alternative to the 6600H |
| Single 8 or 16 TB HDD | No redundancy, and ZFS can detect but not repair corruption |
| 12 TB Ultrastar HC520 pair (~$600-640) | Great value per TB, louder; the upgrade path later |
| server01 SSD swap + adapter | Not needed once server01 is a worker |
