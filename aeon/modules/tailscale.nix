# Fleet-Mesh: Tailscale. Auf jedem NixOS-Gerät importieren.
{ ... }:
{
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";
  # Nach dem ersten Boot einmalig einloggen:  sudo tailscale up
}
