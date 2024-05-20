sudo mkdir -p /usr/local/share/applications

sudo cp /usr/share/applications/{nnn.desktop,btop.desktop,avahi-discover.desktop,assistant.desktop,designer.desktop,linguist.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop,bvnc.desktop,bssh.desktop,fish.desktop,scrcpy-console.desktop,scrcpy.desktop} /usr/local/share/applications/

sudo sed -i '$ a Hidden=true' /usr/local/share/applications/*
