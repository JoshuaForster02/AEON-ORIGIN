# Klickbare AEON-Aktionen im App-Menü — Alltag ohne Terminal.
{ pkgs, ... }:
let
  item = args: pkgs.makeDesktopItem ({ categories = [ "System" ]; } // args);
in
{
  environment.systemPackages = [
    (item {
      name = "aeon-dashboard"; desktopName = "AEON Dashboard";
      comment = "Vitals · Briefing · TRON"; icon = "utilities-system-monitor";
      exec = "${pkgs.firefox}/bin/firefox http://aeon-pi:8080";
    })
    (item {
      name = "aeon-focus"; desktopName = "AEON · Focus an";
      comment = "Lernen — Ablenkungen blocken"; icon = "view-calendar-tasks";
      exec = "aeon-focus";
    })
    (item {
      name = "aeon-unfocus"; desktopName = "AEON · Focus aus";
      comment = "Focus beenden"; icon = "window-close";
      exec = "aeon-unfocus";
    })
    (item {
      name = "aeon-vm"; desktopName = "AEON · VM-Manager";
      comment = "Windows & Distros als VM"; icon = "computer";
      exec = "virt-manager";
    })
    (item {
      name = "aeon-win"; desktopName = "AEON · Windows-VM";
      comment = "Windows starten (GPU umschalten)"; icon = "computer";
      terminal = true; exec = "bash -c \"aeon win; read -n1 -p Fertig...\"";
    })
    (item {
      name = "aeon-update"; desktopName = "AEON · Update";
      comment = "System aktualisieren (OTA)"; icon = "system-software-update";
      terminal = true; exec = "bash -c \"aeon update; read -n1 -p Fertig...\"";
    })
  ];
}
