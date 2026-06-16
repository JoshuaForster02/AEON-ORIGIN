# Futuristische Alltags-Shell: Fish (Autosuggestions) + Starship (AEON-Prompt)
# + ein gebrandetes Greeting beim Terminal-Start.
{ pkgs, ... }:
let
  greet = pkgs.writeShellScriptBin "aeon-greet" ''
    G=$'\033[38;2;201;164;88m'; D=$'\033[38;2;154;147;132m'; T=$'\033[38;2;236;230;216m'; R=$'\033[0m'
    printf "\n  %sA E O N%s\n" "$G" "$R"
    printf "  %s────────────────────────────%s\n" "$D" "$R"
    printf "  %s%s%s  %s·%s  %skernel %s%s\n" "$T" "$(hostname)" "$R" "$D" "$R" "$D" "$(uname -r)" "$R"
    printf "  %s›%s %stron \"…\"   ·   aeon-focus   ·   AEON Dashboard%s\n\n" "$G" "$R" "$D" "$R"
  '';
in
{
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = "aeon-greet";

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$character";
      character = {
        success_symbol = "[›](#C9A458)";
        error_symbol = "[›](#C26B5A)";
      };
      directory.style = "bold #ECE6D8";
      git_branch.style = "#C9A458";
      git_status.style = "#6FA98C";
    };
  };

  users.users.joshua.shell = pkgs.fish;

  environment.systemPackages = [ greet ];
}
