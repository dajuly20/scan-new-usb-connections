PREFIX ?= /usr/local
DESKTOP_DIR ?= $(HOME)/.local/share/applications

install:
	install -d $(PREFIX)/bin
	install -m 755 usb_watcher $(PREFIX)/bin/usb_watcher

install-desktop:
	install -d $(DESKTOP_DIR)
	@echo "[Desktop Entry]" > $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Name=USB Watcher" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Comment=Monitor USB device connections" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Exec=$(PREFIX)/bin/usb_watcher --gui" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Icon=drive-removable-media-usb" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Terminal=false" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Type=Application" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Categories=System;Utility;HardwareSettings;" >> $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Keywords=usb;device;hardware;monitor;" >> $(DESKTOP_DIR)/usb-watcher.desktop
	chmod 644 $(DESKTOP_DIR)/usb-watcher.desktop
	@echo "Desktop entry installed to $(DESKTOP_DIR)/usb-watcher.desktop"
	@update-desktop-database $(DESKTOP_DIR) 2>/dev/null || true

kill:
	@pkill -f "usb_watcher" 2>/dev/null || true
	@rm -f /tmp/usb_watcher.log /tmp/usb_watcher.pid
	@echo "USB-Watcher processes killed and temp files cleaned."

uninstall:
	rm -f $(PREFIX)/bin/usb_watcher
	rm -f $(DESKTOP_DIR)/usb-watcher.desktop
	@update-desktop-database $(DESKTOP_DIR) 2>/dev/null || true
