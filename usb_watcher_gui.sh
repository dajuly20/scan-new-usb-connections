#!/bin/bash

# GUI USB-Watcher mit zenity
# Unterdrücke GLib-Warnungen von zenity
export G_MESSAGES_DEBUG=""
export ZENITY_QUIET=1

function zenity_wrapper() {
    # Wrapper für zenity um Warnungen zu unterdrücken
    G_MESSAGES_DEBUG="" zenity "$@" 2>/dev/null
}

function check_and_install_zenity() {
    # Prüfen ob zenity installiert ist
    if command -v zenity >/dev/null 2>&1; then
        return 0
    fi
    
    echo "❌ Zenity ist nicht installiert!"
    echo ""
    echo "Zenity wird für die GUI benötigt."
    echo ""
    
    # Frage ob installiert werden soll
    read -p "Soll Zenity jetzt installiert werden? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Installiere Zenity..."
        
        # Verschiedene Package Manager probieren
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y zenity
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y zenity
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y zenity
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y zenity
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S zenity
        else
            echo "❌ Kein unterstützter Package Manager gefunden!"
            echo "Bitte installieren Sie Zenity manuell:"
            echo "  Ubuntu/Debian: sudo apt install zenity"
            echo "  Fedora: sudo dnf install zenity"
            echo "  Arch: sudo pacman -S zenity"
            return 1
        fi
        
        # Prüfen ob Installation erfolgreich war
        if command -v zenity >/dev/null 2>&1; then
            echo "✅ Zenity wurde erfolgreich installiert!"
            return 0
        else
            echo "❌ Installation fehlgeschlagen!"
            return 1
        fi
    else
        echo "Installation abgebrochen."
        echo "Verwenden Sie die Terminal-Version: ~/BashScripts/show_last_usb.sh"
        return 1
    fi
}

function get_usb_speed_info() {
    local bus="$1"
    local device="$2"
    
    if [ -d "/sys/bus/usb/devices/$bus-$device" ]; then
        speed_file="/sys/bus/usb/devices/$bus-$device/speed"
        if [ -f "$speed_file" ]; then
            speed=$(cat "$speed_file" 2>/dev/null)
            case $speed in
                1.5)   echo "USB 1.0 Low Speed|1.5 Mbit/s" ;;
                12)    echo "USB 1.1 Full Speed|12 Mbit/s" ;;
                480)   echo "USB 2.0 High Speed|480 Mbit/s" ;;
                5000)  echo "USB 3.0 SuperSpeed|5 Gbit/s" ;;
                10000) echo "USB 3.1 SuperSpeed+|10 Gbit/s" ;;
                20000) echo "USB 3.2 SuperSpeed+|20 Gbit/s" ;;
                *)     echo "USB Unbekannt|${speed} Mbit/s" ;;
            esac
        else
            echo "USB Unbekannt|Unbekannt"
        fi
    else
        echo "USB Unbekannt|Unbekannt"
    fi
}

function get_device_kernel_info() {
    local vendor_product="$1"
    local bus="$2"
    local device="$3"
    
    local device_info=""
    local mount_point=""
    
    # 1. Prüfe direkt auf Block-Devices für diesen Bus/Device
    if [ -d "/sys/bus/usb/devices/$bus-$device" ]; then
        # Schaue nach Block-Devices (Storage)
        local block_devices=$(find "/sys/bus/usb/devices/$bus-$device" -name "block" -type d 2>/dev/null)
        if [ -n "$block_devices" ]; then
            for block_dir in $block_devices; do
                local block_name=$(ls "$block_dir" 2>/dev/null | head -1)
                if [ -n "$block_name" ]; then
                    device_info="� /dev/$block_name (Storage)"
                    
                    # Prüfe Mount-Point
                    mount_point=$(mount | grep "/dev/$block_name" | awk '{print $3}' | head -1)
                    if [ -n "$mount_point" ]; then
                        device_info="$device_info → $mount_point"
                    fi
                    break
                fi
            done
        fi
        
        # Schaue nach SCSI-Devices
        local scsi_devices=$(find "/sys/bus/usb/devices/$bus-$device" -name "scsi_host*" -type d 2>/dev/null)
        if [ -n "$scsi_devices" ]; then
            # Prüfe auf aktuelle Kernel-Logs für SCSI-Devices
            local recent_scsi_logs=$(dmesg | tail -100 | grep -E "(scsi.*CD-ROM|sr[0-9].*scsi)" | tail -5)
            
            if echo "$recent_scsi_logs" | grep -q "CD-ROM"; then
                local sr_device=$(echo "$recent_scsi_logs" | grep -o "sr[0-9]" | tail -1)
                if [ -n "$sr_device" ]; then
                    if [ -z "$device_info" ]; then
                        device_info="� /dev/$sr_device (CD/DVD/Blu-ray)"
                    else
                        device_info="$device_info | /dev/$sr_device"
                    fi
                    
                    # Prüfe Geräte-Details aus dmesg
                    local drive_info=$(echo "$recent_scsi_logs" | grep "mmc drive" | tail -1 | sed 's/.*mmc drive: //')
                    if [ -n "$drive_info" ]; then
                        device_info="$device_info [$drive_info]"
                    fi
                fi
            fi
        fi
    fi
    
    # 2. Fallback: Einfache Kernel-Logs Suche (nur für neue Anschlüsse)
    if [ -z "$device_info" ]; then
        # Schaue nur in die letzten 20 Zeilen von dmesg für kürzlich angeschlossene Geräte
        local recent_logs=$(dmesg | tail -20 | grep -E "(scsi|sr[0-9]|sg[0-9]|sd[a-z])")
        
        if [ -n "$recent_logs" ] && echo "$recent_logs" | grep -q "sr[0-9]"; then
            local sr_device=$(echo "$recent_logs" | grep -o "sr[0-9]" | tail -1)
            if [ -n "$sr_device" ]; then
                device_info="📀 /dev/$sr_device (CD/DVD/Blu-ray)"
            fi
        elif [ -n "$recent_logs" ] && echo "$recent_logs" | grep -q "sd[a-z]"; then
            local sd_device=$(echo "$recent_logs" | grep -o "sd[a-z][0-9]*" | tail -1)
            if [ -n "$sd_device" ]; then
                device_info="💾 /dev/$sd_device (Storage)"
            fi
        fi
    fi
    
    echo "$device_info"
}

# Globales Array für USB-Log
declare -a USB_LOG

function usb_watcher_cli() {
    echo "🔍 USB-Watcher CLI gestartet um $(date '+%H:%M:%S')"
    echo "📋 Überwache USB-Anschlüsse... (Ctrl+C zum Beenden)"
    echo "=============================================="
    
    # USB-Log initialisieren
    USB_LOG=()
    USB_LOG+=("=== USB-Watcher gestartet um $(date '+%H:%M:%S') ===")
    
    # Aktuelle Geräte-Liste speichern
    current_devices=$(lsusb | sort)
    
    # Trap für sauberes Beenden
    trap 'echo -e "\n🛑 USB-Watcher beendet um $(date "+%H:%M:%S")" && exit 0' INT
    
    while true; do
        sleep 1
        
        # Neue Geräte-Liste abrufen
        new_devices=$(lsusb | sort)
        
        # Vergleichen ob sich was geändert hat
        if [ "$current_devices" != "$new_devices" ]; then
            echo ""
            echo "⚡ USB-Änderung erkannt um $(date '+%H:%M:%S')!"
            echo "----------------------------------------"
            
            # Neue Geräte finden
            new_items=$(comm -13 <(echo "$current_devices") <(echo "$new_devices"))
            removed_items=$(comm -23 <(echo "$current_devices") <(echo "$new_devices"))
            
            if [ -n "$new_items" ]; then
                echo "🔌 NEU ANGESCHLOSSEN:"
                while read -r line; do
                    if [ -n "$line" ]; then
                        vendor_product=$(echo "$line" | cut -d' ' -f7-)
                        bus=$(echo "$line" | awk '{print $2}')
                        device=$(echo "$line" | awk '{print $4}' | sed 's/://')
                        
                        # Kurz warten für vollständige Erkennung
                        sleep 1.5
                        speed_info_raw=$(get_usb_speed_info "$bus" "$device")
                        usb_standard=$(echo "$speed_info_raw" | cut -d'|' -f1)
                        usb_speed=$(echo "$speed_info_raw" | cut -d'|' -f2)
                        
                        # Kernel-Device Informationen abrufen
                        sleep 1  # Weitere Wartezeit für Kernel-Logs
                        kernel_info=$(get_device_kernel_info "$vendor_product" "$bus" "$device")
                        
                        echo "  ➕ $vendor_product"
                        echo "     📊 $usb_standard"
                        echo "     ⚡ $usb_speed"
                        echo "     🔗 Bus: $bus, Device: $device"
                        if [ -n "$kernel_info" ]; then
                            echo "     🖥️  $kernel_info"
                        fi
                        
                        # Zum Log hinzufügen
                        if [ -n "$kernel_info" ]; then
                            USB_LOG+=("$(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed | $kernel_info")
                        else
                            USB_LOG+=("$(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed")
                        fi
                    fi
                done <<< "$new_items"
            fi
            
            if [ -n "$removed_items" ]; then
                if [ -n "$new_items" ]; then
                    echo ""
                fi
                echo "❌ ENTFERNT:"
                while read -r line; do
                    if [ -n "$line" ]; then
                        vendor_product=$(echo "$line" | cut -d' ' -f7-)
                        echo "  ➖ $vendor_product"
                        
                        # Zum Log hinzufügen
                        USB_LOG+=("$(date '+%H:%M:%S') ➖ $vendor_product")
                    fi
                done <<< "$removed_items"
            fi
            
            # Aktuelle Liste aktualisieren
            current_devices="$new_devices"
            
            echo "----------------------------------------"
            echo "📋 Weiter überwachen... ($(date '+%H:%M:%S'))"
        fi
    done
}

function show_usb_list_cli() {
    echo "🔍 USB-Geräte Übersicht - $(date '+%H:%M:%S')"
    echo "=============================================="
    
    local device_count=0
    
    while read -r line; do
        bus=$(echo "$line" | awk '{print $2}')
        device=$(echo "$line" | awk '{print $4}' | sed 's/://')
        vendor_product=$(echo "$line" | cut -d' ' -f7-)
        speed_info_raw=$(get_usb_speed_info "$bus" "$device")
        usb_standard=$(echo "$speed_info_raw" | cut -d'|' -f1)
        usb_speed=$(echo "$speed_info_raw" | cut -d'|' -f2)
        
        device_count=$((device_count + 1))
        
        # Kernel-Device Informationen abrufen
        kernel_info=$(get_device_kernel_info "$vendor_product" "$bus" "$device")
        
        echo ""
        echo "📱 Gerät #$device_count: $vendor_product"
        echo "   🔗 Bus: $bus, Device: $device"
        echo "   📊 Standard: $usb_standard"
        echo "   ⚡ Geschwindigkeit: $usb_speed"
        if [ -n "$kernel_info" ]; then
            echo "   🖥️  Device: $kernel_info"
        fi
    done < <(lsusb)
    
    if [ $device_count -eq 0 ]; then
        echo ""
        echo "❌ Keine USB-Geräte gefunden"
    else
        echo ""
        echo "=============================================="
        echo "✅ Insgesamt $device_count USB-Geräte gefunden"
    fi
}

function show_usb_list_gui() {
    # Zenity-Check
    if ! check_and_install_zenity; then
        return 1
    fi
    
    local usb_list=""
    
    while read -r line; do
        bus=$(echo "$line" | awk '{print $2}')
        device=$(echo "$line" | awk '{print $4}' | sed 's/://')
        vendor_product=$(echo "$line" | cut -d' ' -f7-)
        speed_info_raw=$(get_usb_speed_info "$bus" "$device")
        usb_standard=$(echo "$speed_info_raw" | cut -d'|' -f1)
        usb_speed=$(echo "$speed_info_raw" | cut -d'|' -f2)
        
        usb_list="$usb_list$vendor_product|Bus: $bus, Device: $device|$usb_standard|$usb_speed\n"
    done < <(lsusb)
    
    if [ -n "$usb_list" ]; then
        echo -e "$usb_list" | zenity_wrapper --list \
            --title="USB-Geräte Übersicht" \
            --text="Aktuell angeschlossene USB-Geräte:" \
            --column="Gerät" \
            --column="Bus/Device" \
            --column="USB-Standard" \
            --column="Geschwindigkeit" \
            --width=1000 \
            --height=400 \
            --ok-label="Schließen"
    else
        zenity_wrapper --info \
            --title="USB-Geräte" \
            --text="Keine USB-Geräte gefunden"
    fi
}

function usb_watcher_gui() {
    # Zenity-Check
    if ! check_and_install_zenity; then
        echo ""
        echo "💡 Tipp: Verwenden Sie stattdessen die Terminal-Version:"
        echo "   ./usb_watcher_gui.sh --watch-cli"
        return 1
    fi
    
    # Startdialog
    zenity_wrapper --question \
        --title="USB-Watcher GUI" \
        --text="USB-Watcher starten?\n\nDas Programm überwacht USB-Anschlüsse und zeigt Benachrichtigungen bei Änderungen.\n\n⚠️ Hinweis: Für eine stabilere Erfahrung verwenden Sie:\n./usb_watcher_gui.sh --watch-cli" \
        --ok-label="GUI starten" \
        --cancel-label="CLI verwenden"
    
    if [ $? -ne 0 ]; then
        # User wählte CLI
        echo "🔄 Wechsle zu CLI-Modus..."
        usb_watcher_cli
        return 0
    fi
    
    # USB-Log initialisieren
    USB_LOG=()
    USB_LOG+=("=== USB-Watcher gestartet um $(date '+%H:%M:%S') ===")
    
    # Aktuelle Geräte-Liste speichern
    current_devices=$(lsusb | sort)
    
    # Zeige Hinweis-Dialog
    zenity_wrapper --info \
        --title="USB-Watcher gestartet" \
        --text="USB-Watcher läuft jetzt im Hintergrund.\n\nSie erhalten Benachrichtigungen bei USB-Änderungen.\n\nZum Beenden drücken Sie Ctrl+C im Terminal." \
        --timeout=5 &
    
    echo "🔄 USB-Watcher läuft im GUI-Modus..."
    echo "📊 Aktuell $(echo "$current_devices" | wc -l) USB-Geräte erkannt"
    echo ""
    
    # Einfache Überwachungsschleife mit GUI-Benachrichtigungen
    local loop_count=0
    while true; do
        sleep 2
        
        # Neue Geräte-Liste abrufen
        new_devices=$(lsusb | sort)
        
        # Vergleichen ob sich was geändert hat
        if [ "$current_devices" != "$new_devices" ]; then
            echo "🔄 USB-Änderung erkannt!"
            
            # Neue Geräte finden
            new_items=$(comm -13 <(echo "$current_devices") <(echo "$new_devices"))
            removed_items=$(comm -23 <(echo "$current_devices") <(echo "$new_devices"))
            
            notification_text=""
            
            if [ -n "$new_items" ]; then
                notification_text="🔌 NEU ANGESCHLOSSEN:\n"
                while read -r line; do
                    if [ -n "$line" ]; then
                        vendor_product=$(echo "$line" | cut -d' ' -f7-)
                        bus=$(echo "$line" | awk '{print $2}')
                        device=$(echo "$line" | awk '{print $4}' | sed 's/://')
                        
                        # Kurz warten für vollständige Erkennung
                        sleep 1.5
                        speed_info_raw=$(get_usb_speed_info "$bus" "$device")
                        usb_standard=$(echo "$speed_info_raw" | cut -d'|' -f1)
                        usb_speed=$(echo "$speed_info_raw" | cut -d'|' -f2)
                        
                        # Kernel-Device Informationen abrufen
                        sleep 1  # Weitere Wartezeit für Kernel-Logs
                        kernel_info=$(get_device_kernel_info "$vendor_product" "$bus" "$device")
                        
                        notification_text="$notification_text• $vendor_product\n  ⚡ $usb_standard ($usb_speed)\n"
                        if [ -n "$kernel_info" ]; then
                            notification_text="$notification_text  🖥️  $kernel_info\n"
                        fi
                        
                        # Zum Log hinzufügen
                        if [ -n "$kernel_info" ]; then
                            USB_LOG+=("$(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed | $kernel_info")
                            echo "✅ $(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed | $kernel_info"
                        else
                            USB_LOG+=("$(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed")
                            echo "✅ $(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed"
                        fi
                    fi
                done <<< "$new_items"
            fi
            
            if [ -n "$removed_items" ]; then
                if [ -n "$notification_text" ]; then
                    notification_text="$notification_text\n"
                fi
                notification_text="${notification_text}❌ ENTFERNT:\n"
                while read -r line; do
                    if [ -n "$line" ]; then
                        vendor_product=$(echo "$line" | cut -d' ' -f7-)
                        notification_text="$notification_text• $vendor_product\n"
                        
                        # Zum Log hinzufügen
                        USB_LOG+=("$(date '+%H:%M:%S') ➖ $vendor_product")
                        echo "❌ $(date '+%H:%M:%S') ➖ $vendor_product"
                    fi
                done <<< "$removed_items"
            fi
            
            # GUI-Benachrichtigung anzeigen
            zenity_wrapper --info \
                --title="USB-Änderung erkannt!" \
                --text="$notification_text" \
                --timeout=10 &
            
            # Desktop-Benachrichtigung
            if command -v notify-send >/dev/null 2>&1; then
                if [ -n "$new_items" ]; then
                    notify-send "USB-Gerät angeschlossen" "Neues USB-Gerät erkannt" --icon=usb --expire-time=5000
                fi
                if [ -n "$removed_items" ]; then
                    notify-send "USB-Gerät entfernt" "USB-Gerät wurde entfernt" --icon=usb --expire-time=5000
                fi
            fi
            
            # Aktuelle Liste aktualisieren
            current_devices="$new_devices"
        fi
        
        # Status-Update alle 15 Zyklen (30 Sekunden)
        ((loop_count++))
        if (( loop_count % 15 == 0 )); then
            echo "📊 $(date '+%H:%M:%S') - $(echo "$current_devices" | wc -l) USB-Geräte | Log-Einträge: ${#USB_LOG[@]}"
            
            # Optional: Zeige Log-Dialog alle 60 Sekunden
            if (( loop_count % 30 == 0 && ${#USB_LOG[@]} > 1 )); then
                log_text="📋 USB-AKTIVITÄTS-LOG:\n\n"
                # Zeige die letzten 10 Einträge
                start_index=$(( ${#USB_LOG[@]} > 10 ? ${#USB_LOG[@]} - 10 : 0 ))
                for (( i=$start_index; i<${#USB_LOG[@]}; i++ )); do
                    log_text="$log_text${USB_LOG[$i]}\n"
                done
                
                zenity_wrapper --info \
                    --title="USB-Watcher - Aktivitäts-Log" \
                    --text="$log_text" \
                    --timeout=15 \
                    --width=600 \
                    --height=400 &
            fi
        fi
    done
    
    # Abschlussmeldung
    zenity_wrapper --info \
        --title="USB-Watcher" \
        --text="USB-Überwachung beendet."
}

function main_menu_gui() {
    while true; do
        choice=$(zenity_wrapper --list \
            --title="USB-Tools" \
            --text="Wählen Sie eine Option:" \
            --column="Option" \
            --column="Beschreibung" \
            "Aktuelle USB-Geräte anzeigen" "Zeigt alle angeschlossenen USB-Geräte" \
            "USB-Watcher starten" "Überwacht USB-Anschlüsse in Echtzeit" \
            "Beenden" "Programm schließen" \
            --width=500 \
            --height=300)
        
        case "$choice" in
            "Aktuelle USB-Geräte anzeigen")
                show_usb_list_gui
                ;;
            "USB-Watcher starten")
                usb_watcher_gui
                ;;
            "Beenden"|"")
                exit 0
                ;;
        esac
    done
}

# Aliases für GUI-Versionen
alias usbgui="main_menu_gui"
alias usbwatchgui="usb_watcher_gui"
alias usblistgui="show_usb_list_gui"

# Aliases für CLI-Versionen
alias usbcli="show_usb_list_cli"
alias usbwatchcli="usb_watcher_cli"
alias usblistcli="show_usb_list_cli"

function show_help() {
    echo "🔍 USB-Tools - GUI & CLI Versionen"
    echo "=============================================="
    echo ""
    echo "📋 VERFÜGBARE PARAMETER:"
    echo ""
    echo "  --gui              Startet das GUI-Hauptmenü (Standard)"
    echo "  --list             Zeigt USB-Geräte in der GUI"
    echo "  --watch            Startet USB-Watcher in der GUI"
    echo ""
    echo "  --cli              Zeigt USB-Geräte im Terminal"
    echo "  --list-cli         Zeigt USB-Geräte im Terminal"
    echo "  --watch-cli        Startet USB-Watcher im Terminal"
    echo ""
    echo "  --help, -h         Zeigt diese Hilfe"
    echo ""
    echo "📋 BEISPIELE:"
    echo ""
    echo "  $0                 # GUI-Hauptmenü"
    echo "  $0 --cli           # USB-Liste im Terminal"
    echo "  $0 --watch-cli     # USB-Watcher im Terminal"
    echo ""
    echo "⚡ Die CLI-Version zeigt alle USB-Informationen:"
    echo "   • USB-Standard (USB 1.0/1.1/2.0/3.0/3.1/3.2)"
    echo "   • Geschwindigkeit (Mbit/s oder Gbit/s)"
    echo "   • Bus und Device Nummern"
    echo "   • Live-Aktivitätslog"
}

# Wenn direkt ausgeführt
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        "--cli"|"--list-cli")
            show_usb_list_cli
            ;;
        "--watch-cli")
            usb_watcher_cli
            ;;
        "--list")
            show_usb_list_gui
            ;;
        "--watch")
            usb_watcher_gui
            ;;
        "--gui")
            main_menu_gui
            ;;
        "--help"|"-h")
            show_help
            ;;
        "")
            main_menu_gui
            ;;
        *)
            echo "❌ Unbekannter Parameter: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
fi