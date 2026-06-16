# Große Daten auf die 202-GB-Partition (nvme0n1p3, Label "aeon-data"):
# Ollama-Modelle, VM-Images und Games — damit die 30-GB-Root nicht vollläuft.
{ ... }:
{
  fileSystems."/data" = {
    device = "/dev/disk/by-label/aeon-data";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=10s" ];
  };

  # LLM-Modelle (TRON) auf /data statt auf der kleinen Root
  services.ollama.models = "/data/ollama/models";

  # Verzeichnisse anlegen + Rechte
  systemd.tmpfiles.rules = [
    "d /data            0755 root   root      -"
    "d /data/ollama     0750 ollama ollama    -"
    "d /data/ollama/models 0750 ollama ollama -"
    "d /data/vms        0775 root   libvirtd  -"
    "d /data/games      0775 joshua users     -"
  ];
}
