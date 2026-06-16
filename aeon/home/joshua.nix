# AEON Desktop-Design (plasma-manager).
# Stylix liefert Farben/Schriften/Cursor; hier: Icons, Wallpaper, eigene Leiste, Akzent.
{ ... }:
{
  home.stateVersion = "25.05";

  programs.plasma = {
    enable = true;

    workspace = {
      iconTheme = "Papirus-Dark";
      wallpaper = ../assets/aeon-wallpaper.png;
    };

    # Gold-Akzent in der gesamten Oberfläche
    configFile.kdeglobals.General.AccentColor = "201,164,88";

    # AEON-Spotlight: KRunner mittig wie macOS, auf Meta+Space (und Alt+Space).
    # Findet Apps, Dateien, rechnet, Einheiten, Websuche, AEON-Aktionen ("Focus" …).
    krunner = {
      position = "center";
      activateWhenTypingOnDesktop = true;
      historyBehavior = "enableSuggestions";
    };
    shortcuts."org.kde.krunner.desktop"."_launch" = [ "Meta+Space" "Alt+Space" "Search" ];

    # macOS-Look: Menüleiste oben + schwebendes Dock unten
    panels = [
      # Obere Leiste (wie macOS-Menüleiste)
      {
        location = "top";
        height = 28;
        floating = false;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.appmenu"
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
      # Dock unten (schwebend, zentriert, nur Launcher)
      {
        location = "bottom";
        alignment = "center";
        lengthMode = "fit";
        floating = true;
        height = 56;
        widgets = [
          {
            name = "org.kde.plasma.icontasks";
            config.General.launchers = [
              "applications:org.kde.dolphin.desktop"
              "applications:firefox.desktop"
              "applications:kitty.desktop"
              "applications:aeon-dashboard.desktop"
              "applications:anki.desktop"
              "applications:steam.desktop"
              "applications:virt-manager.desktop"
            ];
          }
        ];
      }
    ];
  };
}
