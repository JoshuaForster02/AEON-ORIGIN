#!/bin/bash
SSHOPTS="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
PC=joshua@192.168.0.160
ssh $SSHOPTS $PC 'cat > /tmp/ubi.sh' <<'EOF'
#!/bin/bash
mkdir -p /mnt/ubuntu
mountpoint -q /mnt/ubuntu || mount -o ro /dev/nvme0n1p3 /mnt/ubuntu
echo "=== df Ubuntu ==="; df -h /mnt/ubuntu | tail -1
echo "=== /home Top-Ordner ==="; du -sh /mnt/ubuntu/home/* 2>/dev/null | sort -rh | head
echo "=== Modell-Dateien > 300 MB (safetensors/gguf/bin/pt/ckpt/onnx) ==="
find /mnt/ubuntu/home /mnt/ubuntu/opt /mnt/ubuntu/root -type f \
  \( -iname '*.safetensors' -o -iname '*.gguf' -o -iname '*.bin' -o -iname '*.pt' -o -iname '*.pth' -o -iname '*.ckpt' -o -iname '*.onnx' \) \
  -size +300M -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -40 \
  | awk '{printf "%6.1f GB  %s\n",$1/1073741824,$2}'
echo "=== HF/Ollama/Torch-Caches ==="
du -sh /mnt/ubuntu/home/*/.cache/huggingface 2>/dev/null
du -sh /mnt/ubuntu/home/*/.ollama 2>/dev/null
du -sh /mnt/ubuntu/home/*/.cache/torch 2>/dev/null
echo "=== Summe Modell-Dateien ==="
find /mnt/ubuntu/home /mnt/ubuntu/opt /mnt/ubuntu/root -type f \
  \( -iname '*.safetensors' -o -iname '*.gguf' -o -iname '*.bin' -o -iname '*.pt' -o -iname '*.ckpt' \) \
  -size +300M -printf '%s\n' 2>/dev/null | awk '{s+=$1} END{printf "%.1f GB in grossen Modell-Dateien\n", s/1073741824}'
EOF
ssh $SSHOPTS $PC 'echo aeon | sudo -S bash /tmp/ubi.sh 2>&1'
