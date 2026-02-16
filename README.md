# USB Watcher 🔌

Echtzeit-Überwachung und Analyse von USB-Geräte-Verbindungen unter Linux — CLI und GUI in einem einzigen Python-Script.

## Schnellstart

```bash
# USB-Überwachung starten (CLI, Standard)
./usb_watcher

# Alle USB-Geräte anzeigen
./usb_watcher --list

# GUI mit Tray-Icon starten
./usb_watcher --gui
```

## Installation

```bash
# Schnell
./install.sh

# Oder manuell
sudo make install        # Script nach /usr/local/bin/
make install-desktop     # Menü-Eintrag erzeugen

# Deinstallation
sudo make uninstall
```

Nach der Installation ist `usb_watcher` systemweit verfügbar.

### Abhängigkeiten

**Erforderlich:**
- Python 3
- `lsusb` (`sudo apt install usbutils`)
- `dmesg` (util-linux, normalerweise vorinstalliert)

**Für GUI (`--gui`):**
- PyQt6 oder PyQt5 (`sudo apt install python3-pyqt6` oder `python3-pyqt5`)

## Verwendung

| Kommando | Beschreibung |
|---|---|
| `usb_watcher` | Echtzeit-Überwachung im Terminal (Standard) |
| `usb_watcher --watch` | Echtzeit-Überwachung im Terminal |
| `usb_watcher --list` | Alle USB-Geräte anzeigen und beenden |
| `usb_watcher --gui` | GUI-Fenster + System-Tray-Icon |
| `usb_watcher --help` | Hilfe anzeigen |

### GUI-Modus

- Persistentes Fenster mit Live-Ausgabe (schließt sich nicht automatisch)
- System-Tray-Icon — Fenster schließen versteckt in den Tray
- Rechtsklick auf Tray-Icon → "Beenden" beendet das Programm

## Features

- **Echtzeit USB-Überwachung** — erkennt angeschlossene und entfernte Geräte sofort
- **Detaillierte Infos** pro Gerät:
  - USB-Standard (1.0 / 1.1 / 2.0 / 3.0 / 3.1 / 3.2)
  - Übertragungsgeschwindigkeit
  - Geräteklasse und Treiber
  - Kernel-Device (`/dev/sr0`, `/dev/sda`, etc.)
- **Kernel-Integration** — zeigt Mount-Points, CD/DVD/Blu-ray Info aus dmesg

## Beispiel-Ausgabe

```
🔍 USB-Geräte Übersicht - 09:33:52
==============================================

📱 Gerät #1: Realtek Semiconductor Corp. USB 10/100/1G/2.5G LAN
   🔗 Bus: 002, Device: 003
   📊 Standard: USB 3.2 SuperSpeed+
   ⚡ Geschwindigkeit: 20 Gbit/s
   🏷️  Klasse: Vendor Specific Class
   🔧 Treiber: r8152

📱 Gerät #2: Intel Corp. AX210 Bluetooth
   🔗 Bus: 003, Device: 006
   📊 Standard: USB 2.0 High Speed
   ⚡ Geschwindigkeit: 480 Mbit/s
   🏷️  Klasse: Wireless
   🔧 Treiber: btusb

==============================================
✅ Insgesamt 2 USB-Geräte gefunden
```

## Troubleshooting

```bash
# Prüfen ob lsusb funktioniert
lsusb

# Prüfen ob dmesg zugänglich ist
dmesg | tail -10

# PyQt installieren falls GUI nicht startet
sudo apt install python3-pyqt6
```

## Lizenz

**Beerware License** 🍺

```
"THE BEER-WARE LICENSE" (Revision 42):
<dajuly20@github.com> wrote this file. As long as you retain this notice you
can do whatever you want with this stuff. If we meet some day, and you think
this stuff is worth it, you can buy me a beer in return.
```

**Prost! 🍻**
