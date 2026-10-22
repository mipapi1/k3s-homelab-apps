# plex

[Plex](https://www.plex.tv) (linuxserver.io image) with **hardware transcoding on the
Intel iGPU** (Quick Sync), on k3s VMs that get their host's iGPU passed through.

How the GPU gets to Plex:

1. **Proxmox** passes the host's iGPU to the VM through a PCI resource mapping
   ([terraform-proxmox-vm](https://github.com/mipapi1/terraform-proxmox-vm), `pci_mapping`).
2. **The VM** gets a kernel with GPU drivers and the firmware (role `igpu` of
   [ansible-k3s-homelab](https://github.com/mipapi1/ansible-k3s-homelab)), so
   `/dev/dri/renderD128` exists.
3. **The Intel GPU device plugin** ([`apps/intel-gpu`](../intel-gpu)) offers it to
   Kubernetes as `gpu.intel.com/i915`.
4. **Plex** asks for one (`limits` in `plex.yaml`) and gets the device mounted. In Plex:
   Settings → Transcoder → "Use hardware acceleration when available" (needs Plex Pass).

Check it: while something transcodes, the Plex dashboard shows "(hw)" next to the stream.

Storage: database on Longhorn (`plex-config`), the library from the NAS over NFS
(`media-library`, read as `/data`). Set the NAS address and export in `storage.yaml`.

Remote access: port 32400 is open on every node (k3s ServiceLB); forward it on the router
to one node and set that port under Settings → Remote Access → "Manually specify public
port".
