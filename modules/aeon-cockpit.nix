# Cockpit — Web-Oberfläche zur VM-Fernsteuerung (z.B. vom Mac/iPhone im Tailnet).
# Im System selbst nutzt du virt-manager (native App, eigenes Fenster).
# Erreichbar unter https://aeon-rig:9090  (Login: joshua / dein Passwort).
#
# Toggle: Falls der Build hieran scheitert (Paketname cockpit-machines),
#         den Import in configuration.nix auskommentieren — VMs gehen weiter
#         über virt-manager.
{ pkgs, ... }:
{
  services.cockpit = {
    enable = true;
    port = 9090;
  };
  networking.firewall.allowedTCPPorts = [ 9090 ];
  # Hinweis: das VM-Plugin (cockpit-machines) ist in nixpkgs 25.05 nicht als Paket
  # vorhanden. Cockpit selbst (Remote-System/Terminal/Logs) läuft; VMs verwaltest du
  # nativ über virt-manager. Sobald cockpit-machines paketiert ist, ergänzen wir es.
}
