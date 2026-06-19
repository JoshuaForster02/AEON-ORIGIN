# AEON-Flaggschiff · Windows-PC (Ryzen + RX 6800) · Dual-Boot NixOS
# Fertiger, gebrandeter Desktop. hardware-configuration.nix generiert der Installer.
{ config, pkgs, lib, ... }:
let
  # Ablenkende Domains für den Focus-Modus
  focusBlocklist = ''
    0.0.0.0 youtube.com www.youtube.com m.youtube.com
    0.0.0.0 instagram.com www.instagram.com
    0.0.0.0 tiktok.com www.tiktok.com
    0.0.0.0 reddit.com www.reddit.com
    0.0.0.0 x.com twitter.com www.twitter.com
    0.0.0.0 netflix.com www.netflix.com
    0.0.0.0 twitch.tv www.twitch.tv
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/aeon-ota.nix
    ../../modules/aeon-winvm.nix
    ../../modules/aeon-theme.nix     # AEON-Design (Stylix + Wallpaper)
    ../../modules/tailscale.nix      # Fleet-Mesh
    ../../modules/aeon-modes.nix     # aeon-focus / aeon-unfocus
    ../../modules/aeon-tron.nix      # `tron "..."` — LLM im Terminal
    ../../modules/aeon-shell.nix     # Fish + Starship + Greeting
    ../../modules/aeon-cli.nix       # `aeon` — das Command-Center
    ../../modules/aeon-virtualisation.nix  # KVM/libvirt + GPU-Passthrough (Hook + vendor-reset)
    ../../modules/aeon-launchers.nix # Klickbare AEON-Aktionen im App-Menü
    ../../modules/aeon-sound.nix     # Eigener Startup-Sound beim Login
    ../../modules/aeon-cockpit.nix   # Web-VM-Fernsteuerung
    ../../modules/aeon-vitals.nix    # Vitals-Reporter (Anki & Fokus)
    # ../../modules/aeon-storage.nix # DEAKTIVIERT: nvme0n1p3 ist Ubuntu (nicht frei!)
  ];

  # ── Dual-Boot: GRUB mit AEON-Theme, erkennt Windows automatisch ──
  # (Falls GRUB mal zickt: diesen Block durch systemd-boot ersetzen:
  #   boot.loader.systemd-boot.enable = true;
  #   boot.loader.systemd-boot.configurationLimit = 8; )
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;                  # findet Windows
    theme = lib.mkForce ../../assets/grub;   # AEON Noir-Gold-Bootmenü (Vorrang)
    gfxmodeEfi = "1920x1080";
    configurationLimit = 8;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "quiet" ];
  boot.plymouth.enable = true;        # gebrandeter Boot-Splash (von Stylix gethemed)
  boot.tmp.cleanOnBoot = true;

  # ── NTFS: Windows-Partitionen & -Spiele lesen/schreiben (Dolphin mountet sie) ──
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "aeon-rig";
  networking.networkmanager.enable = true;

  # ── Region: Deutsch ──
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
  services.xserver.xkb = { layout = "de"; variant = ""; };

  # ── AMD Ryzen + Firmware ──
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # ── RX 6800 (amdgpu) + 32-bit für Gaming ──
  # RADV/Mesa liefert Vulkan out-of-the-box — robust fürs Erst-Setup.
  # (amdvlk / ROCm-OpenCL bei Bedarf später per OTA ergänzen.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ── Audio (PipeWire) ──
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Desktop: KDE Plasma 6 (Wayland) ──
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ── Unfree erlauben + Flakes + automatische Pflege ──
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 14d"; };

  # ── Gaming ──
  programs.steam.enable = true;
  programs.gamemode.enable = true;

  # ── Lokale LLM (TRONs Gehirn) ──
  # GPU-Beschleunigung mit ROCm (kompatibel mit RX 6800 durch GFX-Override)
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    rocmOverrideGfx = "10.3.0";
  };

  # ── Game-Streaming an Mac/iPhone (Moonlight) ──
  services.sunshine = { enable = true; openFirewall = true; capSysAdmin = true; };

  # ── System-Pflege ──
  services.openssh.enable = true;
  services.fwupd.enable = true;        # Firmware-Updates
  services.fstrim.enable = true;       # SSD-TRIM
  networking.interfaces.eth0.wakeOnLan.enable = true;   # Pi weckt den PC

  # ── Browser + Lern-Apps ──
  programs.firefox.enable = true;

  # ── Schriften (AEON-Designsprache + sauberes Rendering) ──
  fonts.packages = with pkgs; [
    inter
    ibm-plex
    google-fonts
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];

  environment.systemPackages = with pkgs; [
    git vim wget curl htop fastfetch
    kitty                       # Terminal (von Stylix gethemed)
    anki-bin                    # Lernen (prebuilt — schneller/robuster als Quell-Build)
    obsidian                    # Notizen
    vlc
    mangohud protonup-qt lutris # Gaming-Komfort
    papirus-icon-theme          # dunkle Icons (von plasma-manager gesetzt)
    ntfs3g                      # Windows-NTFS-Partitionen
    claude-code                 # Claude im Terminal (Agent)
  ];

  # ── Focus-Modus als Boot-Profil (hartes Blocking) ──
  specialisation.focus.configuration = {
    system.nixos.tags = [ "focus" ];
    networking.extraHosts = focusBlocklist;
  };

  # ── Gaming-Boot-Profil (Proxmox-Style): RX 6800 ab Boot an VFIO,
  #    Desktop aus, Windows-VM startet automatisch. Im GRUB "AEON Gaming" wählen.
  #    Zurück zu AEON = normal booten. Kein Live-Handoff → kein Freeze.
  specialisation.gaming.configuration = {
    system.nixos.tags = [ "gaming" ];
    # GPU + Audio von Boot an für VFIO reservieren (amdgpu fasst sie nie an)
    boot.kernelParams = [ "vfio-pci.ids=1002:73bf,1002:ab28" ];
    boot.initrd.kernelModules = [ "vfio_pci" "vfio_iommu_type1" "vfio" ];
    boot.blacklistedKernelModules = [ "amdgpu" ];
    # Desktop in diesem Profil aus (Host headless wie ein Hypervisor)
    services.displayManager.sddm.enable = lib.mkForce false;
    services.displayManager.autoLogin.enable = lib.mkForce false;
    # Windows-VM automatisch starten, sobald libvirt bereit ist
    systemd.services.aeon-winauto = {
      description = "AEON Gaming: Windows-VM Autostart";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.libvirt}/bin/virsh start windows";
      };
    };
  };

  users.users.joshua = {
    isNormalUser = true;
    description = "Joshua";
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "kvm" ];
    initialPassword = "aeon";   # ⚠️ nach erstem Login ändern:  passwd
  };

  # ── Passwortloses Sudo für Spezialisierungs-Switches (Fokus-Wechsel) ──
  security.sudo.extraRules = [
    {
      users = [ "joshua" ];
      commands = [
        { command = "/run/current-system/specialisation/focus/bin/switch-to-configuration"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/bin/switch-to-configuration"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  system.stateVersion = "25.05";
}
