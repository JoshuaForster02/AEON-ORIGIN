# AEON Startup-Sound — spielt beim grafischen Login einen eigenen Klang.
{ pkgs, ... }:
{
  environment.etc."aeon/aeon-startup.wav".source = ../assets/sound/aeon-startup.wav;

  systemd.user.services.aeon-startup-sound = {
    description = "AEON Startup-Sound";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.pulseaudio}/bin/paplay /etc/aeon/aeon-startup.wav";
    };
  };
}
