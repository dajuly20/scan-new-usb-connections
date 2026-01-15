# USB Connection Scanner 🔌

Ein fortschrittliches Tool zur Überwachung und Analyse von USB-Geräte-Verbindungen unter Linux.

## 🚀 Features

- **Echtzeit USB-Überwachung** - Erkennt angeschlossene und entfernte USB-Geräte sofort
- **Detaillierte Geräteinformationen**:
  - 📊 USB-Standard (USB 1.0/1.1/2.0/3.0/3.1/3.2)
  - ⚡ Übertragungsgeschwindigkeit (1.5 Mbit/s bis 20 Gbit/s)
  - 🏷️ Geräteklasse (Mass Storage, Audio, Video, Hub, etc.)
  - 🔧 Verwendeter Treiber (usb-storage, snd-usb-audio, etc.)
  - 🖥️ Kernel-Device (/dev/sr0, /dev/sda, /dev/sg0, etc.)
- **Kernel-Integration** - Zeigt /dev/sr0 Informationen für CD/DVD/Blu-ray Laufwerke
- **GUI und CLI Modi** - Zenity-basierte grafische Oberfläche oder Terminal-Ausgabe
- **Activity Log** - Protokolliert alle USB-Aktivitäten mit Zeitstempel

## 📁 Dateien

- `scanusbconnections` - Hauptscript (CLI)
- `usb_watcher_gui.sh` - GUI-Version mit Zenity

## 📦 Installation

```bash
# Schnelle Installation
./install.sh

# Oder manuell
sudo make install

# Deinstallation
sudo make uninstall
```

Nach der Installation kann `scanusbconnections` systemweit aufgerufen werden.

## 🛠️ Verwendung

### Schnellstart
```bash
# USB-Überwachung starten (Standard)
./scanusbconnections

# USB-Geräte auflisten
./scanusbconnections --list-cli

# GUI-Version starten
./usb_watcher_gui.sh --gui
```

### Alle Parameter
```bash
./scanusbconnections --help
```

**Verfügbare Optionen:**
- (ohne Parameter) - Startet Echtzeit-Überwachung im Terminal (Standard)
- `--list-cli` - Zeigt alle aktuell angeschlossenen USB-Geräte
- `--watch-cli` - Startet Echtzeit-Überwachung im Terminal
- `--help` - Zeigt Hilfe-Information

## 📋 Beispiel-Ausgabe

### USB-Geräte Liste
```
🔍 USB-Geräte Übersicht - 09:33:52
==============================================

📱 Gerät #1: Verbatim, Ltd Verbatim 4K BD RW
   🔗 Bus: 004, Device: 037
   📊 Standard: USB 3.0 SuperSpeed
   ⚡ Geschwindigkeit: 5 Gbit/s
   🏷️ Klasse: Mass Storage
   🔧 Treiber: usb-storage
   🖥️ Device: 📀 /dev/sr0 (Blu-ray Reader/Writer)
```

### Echtzeit-Überwachung
```
⚡ USB-Änderung erkannt um 09:35:30!
----------------------------------------
🔌 NEU ANGESCHLOSSEN:
  ➕ Realtek Semiconductor Corp. USB 3.0 Hub
     📊 Standard: USB 3.0 SuperSpeed
     ⚡ Geschwindigkeit: 5 Gbit/s
     🏷️ Klasse: Hub
     🔧 Treiber: hub/4p
     🔗 Bus: 004, Device: 038
     🖥️ Kernel: 💾 /dev/sdb (USB Storage) → gemountet als /media/julian/USB_DRIVE
```

## 🔧 Technische Details

### Erkannte USB-Standards
- **USB 1.0 Low Speed** - 1.5 Mbit/s
- **USB 1.1 Full Speed** - 12 Mbit/s  
- **USB 2.0 High Speed** - 480 Mbit/s
- **USB 3.0 SuperSpeed** - 5 Gbit/s
- **USB 3.1 SuperSpeed+** - 10 Gbit/s
- **USB 3.2 SuperSpeed+** - 20 Gbit/s

### Erkannte Geräteklassen
- Mass Storage (USB-Sticks, Festplatten)
- Audio (Soundkarten, Mikrofone)
- Video (Webcams, Capture-Karten)
- Hub (USB-Hubs, Docking-Stations)
- Human Interface Device (Tastaturen, Mäuse)
- Wireless (Bluetooth, WLAN-Adapter)

### Kernel-Device Erkennung
- **📀 /dev/sr0-sr9** - CD/DVD/Blu-ray Laufwerke
- **💾 /dev/sda-sdz** - Storage-Geräte (USB-Sticks, Festplatten)
- **🔧 /dev/sg0-sg9** - SCSI Generic Devices

## ⚙️ Abhängigkeiten

### Erforderlich
- `lsusb` (usbutils Paket)
- `dmesg` (util-linux Paket)
- `bash` >= 4.0

### Optional (für GUI)
- `zenity` (wird automatisch installiert falls nicht vorhanden)
- `notify-send` (libnotify-bin Paket)

## 🐛 Troubleshooting

### Keine detaillierten Informationen sichtbar
```bash
# Prüfen ob lsusb -v funktioniert
sudo lsusb -v

# Prüfen ob dmesg zugänglich ist  
dmesg | tail -10
```

### GUI startet nicht
```bash
# Zenity installieren
sudo apt install zenity -y

# Fallback zu CLI-Modus
./scanusbconnections --watch-cli
```

## 📝 Changelog

### Version 1.0 (Oktober 2025)
- ✅ Grundlegende USB-Erkennung mit lsusb
- ✅ Echtzeit-Überwachung mit diff-Algorithmus
- ✅ Kernel-Device Information aus dmesg
- ✅ GUI-Version mit Zenity
- ✅ Detaillierte USB-Informationen mit lsusb -v
- ✅ Activity-Log mit Zeitstempel
- ✅ Mount-Point Erkennung für Storage-Geräte

## 📄 Lizenz

Dieses Projekt steht unter der **Beerware License** 🍺

```
"THE BEER-WARE LICENSE" (Revision 42):
<dajuly20@github.com> wrote this file. As long as you retain this notice you
can do whatever you want with this stuff. If we meet some day, and you think
this stuff is worth it, you can buy me a beer in return.
```

**Das bedeutet:**
- ✅ Du kannst mit dieser Software machen was du willst
- 🍺 Wenn sie dir gefällt, schuldest du dem Autor ein Bier
- 🤝 Falls wir uns mal treffen und du denkst es war das wert, gib mir ein Bier aus
- 🎉 Das war's! Keine anderen Verpflichtungen oder Beschränkungen

---

**Entwickelt für BashScripts Repository**  
*Optimiert für Ubuntu/Debian-basierte Systeme*

**Prost! 🍻**