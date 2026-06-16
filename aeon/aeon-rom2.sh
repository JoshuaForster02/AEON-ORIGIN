#!/bin/bash
S="-i $HOME/.ssh/aeon_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
B="/Users/joshuaforster/Library/Application Support/Claude/local-agent-mode-sessions/e343dd3f-a571-48d5-b810-fbe303f9c671/e6563f92-1cf4-4b49-9d05-84bb06906b57/local_b5c92f40-959f-48f1-9917-c09106bb27de/outputs"
cat "$B/insertrom.awk" | ssh $S joshua@192.168.0.160 'cat > /tmp/insertrom.awk'
ssh $S joshua@192.168.0.160 'echo aeon | sudo -S bash -c "
export PATH=/run/current-system/sw/bin:\$PATH
virsh -c qemu:///system dumpxml windows > /tmp/w.xml
awk -f /tmp/insertrom.awk /tmp/w.xml > /tmp/w2.xml
virsh -c qemu:///system define /tmp/w2.xml 2>&1 | tail -1
echo ROM-Zeile:; grep rx6800 /tmp/w2.xml
" 2>/dev/null' 2>&1 | grep -v Warning
