sudo mkdir -p /usr/local/share/applications

sudo cp /usr/share/applications/{avahi-discover.desktop,assistant.desktop,designer.desktop,linguist.desktop,qdbusviewer.desktop,qv4l2.desktop,qvidcap.desktop,yad-settings.desktop,vim.desktop,bvnc.desktop,bssh.desktop,fish.desktop,yad-icon-browser.desktop,lstopo.desktop,gvim.desktop} /usr/local/share/applications/

sudo sed -i '$ a Hidden=true' /usr/local/share/applications/*