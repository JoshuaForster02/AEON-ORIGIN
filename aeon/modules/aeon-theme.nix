# AEON Design-System als Code (Stylix) — gilt systemweit auf NixOS-Geräten.
# Farbwerte stammen 1:1 aus AEON-Design-System.md.
{ pkgs, ... }:
{
  stylix = {
    enable = true;
    polarity = "dark";

    # AEON base16 (Noir Gold)
    base16Scheme = {
      base00 = "0E0D0B"; # canvas
      base01 = "15130F"; # surface-1
      base02 = "1B1813"; # surface-2
      base03 = "6A6356"; # tertiary
      base04 = "9C9384"; # secondary
      base05 = "ECE6D8"; # primary text
      base06 = "F2EDE2";
      base07 = "FBF8F1";
      base08 = "C26B5A"; # terra
      base09 = "C9A458"; # gold
      base0A = "D8A84B"; # amber gold
      base0B = "6FA98C"; # sage
      base0C = "8FB3AE"; # muted teal
      base0D = "B9925A"; # warm tan
      base0E = "A98B6F"; # taupe
      base0F = "8A7338"; # gold-dark
    };

    # AEON-Wallpaper (Pflichtfeld für Stylix) — liegt im Repo bei.
    image = ../assets/aeon-wallpaper.png;

    fonts = {
      serif     = { package = pkgs.google-fonts; name = "Newsreader"; };
      sansSerif = { package = pkgs.inter;        name = "Inter"; };
      monospace = { package = pkgs.ibm-plex;     name = "IBM Plex Mono"; };
      sizes = { applications = 11; terminal = 12; desktop = 11; popups = 11; };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    opacity.terminal = 0.95;
  };
}
