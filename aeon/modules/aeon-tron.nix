# TRON im Terminal: `tron "..."` fragt die lokale LLM (Ollama auf der RX 6800).
# Von jedem Terminal aus — das intuitive, futuristische Herzstück.
{ pkgs, ... }:
let
  tron = pkgs.writeShellScriptBin "tron" ''
    set -u
    URL="''${OLLAMA_URL:-http://localhost:11434}"
    MODEL="''${TRON_MODEL:-qwen2.5:14b}"
    GOLD=$'\033[38;2;201;164;88m'; DIM=$'\033[38;2;154;147;132m'; R=$'\033[0m'
    if [ "$#" -eq 0 ]; then
      printf "%sTRON%s › sag mir, was du brauchst:  %stron \"fasse die Vorlesung zusammen\"%s\n" \
        "$GOLD" "$R" "$DIM" "$R"; exit 0
    fi
    PROMPT="$*"
    printf "%sTRON%s denkt …\r" "$GOLD" "$R"
    DATA=$(${pkgs.jq}/bin/jq -nc --arg m "$MODEL" --arg p "$PROMPT" \
      '{model:$m, prompt:$p, stream:false}')
    RESP=$(${pkgs.curl}/bin/curl -s --max-time 120 "$URL/api/generate" -d "$DATA" \
      | ${pkgs.jq}/bin/jq -r '.response // empty')
    printf "                 \r"
    if [ -z "$RESP" ]; then
      printf "%sTRON offline%s — lokale LLM (Ollama) nicht erreichbar.\n" "$DIM" "$R"
      printf "%sStarte den PC / prüfe:  systemctl status ollama%s\n" "$DIM" "$R"
    else
      printf "%sTRON%s ▸ %s\n" "$GOLD" "$R" "$RESP"
    fi
  '';
in
{
  environment.systemPackages = [ tron ];
}
