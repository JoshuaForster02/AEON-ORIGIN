{ print }
!done && /<\/source>/ { print "      <rom file='/etc/aeon/vbios/rx6800.rom'/>"; done=1 }
