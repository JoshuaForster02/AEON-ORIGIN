# ISO auf dem Mac bauen (Docker)

Die ISO baut lokal auf dem M1 über einen x86_64-Linux-Nix-Builder im Container.

## Quickstart

```bash
# Docker Desktop muss laufen.
cd aeon
chmod +x build/build-iso.sh
./build/build-iso.sh
# ISO landet in ./out/*.iso
```

Das Skript setzt die kniffligen Flags schon selbst:
`experimental-features = nix-command flakes`, **`filter-syscalls = false`** und
**`sandbox = false`** — ohne die crasht ein x86-Nix-Build unter QEMU-Emulation.

**Eigenen Builder nutzen** (falls dein flynnos-builder Nix + Flakes kann):

```bash
AEON_BUILDER_IMAGE=flynnos-builder ./build/build-iso.sh
# oder per Digest:
AEON_BUILDER_IMAGE=flynnos-builder@sha256:83a2fae3ffe46e000b112aadf9c1512c6cf0e730f1e165c64e83293accbefb6b ./build/build-iso.sh
```

## Hinweise

- **Emulation = langsam.** Der x86-Build läuft auf dem M1 über Rosetta/QEMU. Funktioniert, dauert aber deutlich länger als nativ. Für schnelle Builds bleibt **GitHub Actions** die bequemste Option (`.github/workflows/build-iso.yml`).
- **Ressourcen.** Docker Desktop braucht genug RAM/Disk (ISO-Build lädt viele Pakete). Falls der Build mit „no space" abbricht: Docker-Desktop-Disk-Image vergrößern.
- **`--platform linux/amd64`** setzt voraus, dass in Docker Desktop „Use Rosetta / amd64 emulation" aktiv ist (Standard bei aktuellen Versionen).
