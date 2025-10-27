#!/bin/bash

# Einfacher USB-Watcher mit Kernel-Device Information
# Basierend auf dem ursprünglichen Script, aber ohne komplizierte find-Operationen

function check_and_install_zenity() {
    if ! command -v zenity >/dev/null 2>&1; then
        echo "⚠️  zenity ist nicht installiert."
        echo ""
        read -p "Soll zenity installiert werden? (j/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[JjYy]$ ]]; then
            echo "📦 Installiere zenity..."
            sudo apt update && sudo apt install -y zenity
        else
            return 1
        fi
    fi
    return 0
}

function zenity_wrapper() {
    # Zenity mit Fehler-Unterdrückung
    zenity "$@" 2>/dev/null
}

function get_usb_detailed_info() {
    local bus="$1"
    local device="$2"
    
    # Alternative Methode: Verwende lsusb -v für detaillierte Informationen
    local vendor_id=""
    local product_id=""
    local device_class=""
    local speed_info=""
    local driver=""
    
    # Hole Vendor:Product ID aus lsusb
    local lsusb_line=$(lsusb | grep "Bus $bus.*Device $device")
    if [ -n "$lsusb_line" ]; then
        local ids=$(echo "$lsusb_line" | grep -o "ID [0-9a-f]*:[0-9a-f]*" | cut -d' ' -f2)
        vendor_id=$(echo "$ids" | cut -d':' -f1)
        product_id=$(echo "$ids" | cut -d':' -f2)
    fi
    
    # Hole detaillierte Informationen mit lsusb -v (begrenzt auf dieses Gerät)
    if [ -n "$vendor_id" ] && [ -n "$product_id" ]; then
        local detailed_output=$(lsusb -v -d "$vendor_id:$product_id" 2>/dev/null | head -50)
        
        # Extrahiere Geschwindigkeit
        speed_info=$(echo "$detailed_output" | grep -o "bcdUSB.*[0-9]\.[0-9]*" | head -1 | sed 's/bcdUSB *//')
        
        # Extrahiere Device Class
        device_class=$(echo "$detailed_output" | grep -o "bDeviceClass.*" | head -1 | sed 's/bDeviceClass *[0-9]* *//' | cut -d' ' -f1-2)
        if [ -z "$device_class" ]; then
            device_class=$(echo "$detailed_output" | grep -o "bInterfaceClass.*" | head -1 | sed 's/bInterfaceClass *[0-9]* *//' | cut -d' ' -f1-2)
        fi
    fi
    
    # Fallback: Versuche lsusb -t Zuordnung über Bus-Struktur
    local usb_tree_info=""
    if [ -z "$device_class" ]; then
        # Suche in lsusb -t nach Bus und ungefährer Position
        usb_tree_info=$(lsusb -t | grep "Bus $bus" -A 20 | grep -E "(Mass Storage|Audio|Video|Hub|Human Interface|Wireless)" | head -1)
        
        if [ -n "$usb_tree_info" ]; then
            device_class=$(echo "$usb_tree_info" | grep -o 'Class=[^,]*' | sed 's/Class=//')
            driver=$(echo "$usb_tree_info" | grep -o 'Driver=[^,]*' | sed 's/Driver=//')
            local speed_raw=$(echo "$usb_tree_info" | grep -o '[0-9.]*M$' | sed 's/M$//')
            speed_info="$speed_raw"
        fi
    fi
    
    # Normalisiere und formatiere die Ausgabe
    local speed_standard=""
    local speed_display=""
    
    # Bestimme USB-Standard basierend auf verfügbarer Geschwindigkeit
    if [ -n "$speed_info" ]; then
        case $speed_info in
            1.0*|1.1*)  speed_standard="USB 1.1 Full Speed"; speed_display="12 Mbit/s" ;;
            2.0*)       speed_standard="USB 2.0 High Speed"; speed_display="480 Mbit/s" ;;
            3.0*)       speed_standard="USB 3.0 SuperSpeed"; speed_display="5 Gbit/s" ;;
            3.1*)       speed_standard="USB 3.1 SuperSpeed+"; speed_display="10 Gbit/s" ;;
            3.2*)       speed_standard="USB 3.2 SuperSpeed+"; speed_display="20 Gbit/s" ;;
            1.5)        speed_standard="USB 1.0 Low Speed"; speed_display="1.5 Mbit/s" ;;
            12)         speed_standard="USB 1.1 Full Speed"; speed_display="12 Mbit/s" ;;
            480)        speed_standard="USB 2.0 High Speed"; speed_display="480 Mbit/s" ;;
            5000)       speed_standard="USB 3.0 SuperSpeed"; speed_display="5 Gbit/s" ;;
            10000)      speed_standard="USB 3.1 SuperSpeed+"; speed_display="10 Gbit/s" ;;
            20000)      speed_standard="USB 3.2 SuperSpeed+"; speed_display="20 Gbit/s" ;;
            *)          speed_standard="USB ${speed_info}"; speed_display="${speed_info} Mbit/s" ;;
        esac
    else
        speed_standard="USB Unbekannt"
        speed_display="Unbekannt"
    fi
    
    # Fallback-Werte setzen
    if [ -z "$device_class" ]; then
        device_class="Unbekannt"
    fi
    
    if [ -z "$driver" ] || [ "$driver" = "[none]" ]; then
        driver="Kein Treiber"
    fi
    
    # Rückgabe: Standard|Geschwindigkeit|Klasse|Treiber
    echo "$speed_standard|$speed_display|$device_class|$driver"
}

function get_kernel_device_info() {
    local vendor_product="$1"
    local is_new="$2"  # "new" wenn gerade angeschlossen
    
    local device_info=""
    
    # Nur bei neu angeschlossenen Geräten nach aktuellen Kernel-Logs suchen
    if [ "$is_new" = "new" ]; then
        echo "🔍 Suche nach Kernel-Device Info für: $vendor_product" >&2
        
        # Hole die letzten Kernel-Meldungen
        local recent_logs=$(dmesg | tail -50)
        
        # Suche nach SR-Devices (CD/DVD/Blu-ray)
        if echo "$recent_logs" | grep -q "sr[0-9].*scsi.*CD-ROM"; then
            local sr_line=$(echo "$recent_logs" | grep "sr[0-9].*scsi.*CD-ROM" | tail -1)
            local sr_device=$(echo "$sr_line" | grep -o "sr[0-9]")
            
            if [ -n "$sr_device" ]; then
                if echo "$sr_line" | grep -q "BD-RE"; then
                    device_info="📀 /dev/$sr_device (Blu-ray Reader/Writer)"
                elif echo "$sr_line" | grep -q "DVD"; then
                    device_info="📀 /dev/$sr_device (DVD Drive)"
                else
                    device_info="📀 /dev/$sr_device (CD-ROM)"
                fi
                
                # Hole Drive-Details
                local drive_details=$(echo "$recent_logs" | grep "mmc drive" | tail -1)
                if [ -n "$drive_details" ]; then
                    local capabilities=$(echo "$drive_details" | sed 's/.*mmc drive: //' | cut -d' ' -f1-3)
                    device_info="$device_info - $capabilities"
                fi
            fi
        fi
        
        # Suche nach SD-Devices (Storage)
        if [ -z "$device_info" ]; then
            if echo "$recent_logs" | grep -q "sd[a-z][0-9]*.*Attached"; then
                local sd_line=$(echo "$recent_logs" | grep "sd[a-z][0-9]*.*Attached" | tail -1)
                local sd_device=$(echo "$sd_line" | grep -o "sd[a-z][0-9]*")
                
                if [ -n "$sd_device" ]; then
                    device_info="💾 /dev/$sd_device (USB Storage)"
                    
                    # Warte kurz und prüfe Mount-Status
                    sleep 2
                    local mount_point=$(mount | grep "/dev/$sd_device" | awk '{print $3}' | head -1)
                    if [ -n "$mount_point" ]; then
                        device_info="$device_info → gemountet als $mount_point"
                    fi
                fi
            fi
        fi
        
        # Suche nach SG-Devices (SCSI Generic)
        if echo "$recent_logs" | grep -q "sg[0-9].*Attached"; then
            local sg_line=$(echo "$recent_logs" | grep "sg[0-9].*Attached" | tail -1)
            local sg_device=$(echo "$sg_line" | grep -o "sg[0-9]")
            
            if [ -n "$sg_device" ]; then
                if [ -n "$device_info" ]; then
                    device_info="$device_info | /dev/$sg_device (SCSI)"
                else
                    device_info="🔧 /dev/$sg_device (SCSI Generic)"
                fi
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
    
    # Überwachungsschleife
    while true; do
        sleep 2
        
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
                        
                        # Hole detaillierte USB-Informationen mit lsusb -t
                        detailed_info=$(get_usb_detailed_info "$bus" "$device")
                        usb_standard=$(echo "$detailed_info" | cut -d'|' -f1)
                        usb_speed=$(echo "$detailed_info" | cut -d'|' -f2)
                        device_class=$(echo "$detailed_info" | cut -d'|' -f3)
                        driver=$(echo "$detailed_info" | cut -d'|' -f4)
                        
                        echo "  ➕ $vendor_product"
                        echo "     📊 Standard: $usb_standard"
                        echo "     ⚡ Geschwindigkeit: $usb_speed"
                        echo "     🏷️  Klasse: $device_class"
                        echo "     🔧 Treiber: $driver"
                        echo "     🔗 Bus: $bus, Device: $device"
                        
                        # Kernel-Device Informationen abrufen (für neue Geräte)
                        kernel_info=$(get_kernel_device_info "$vendor_product" "new")
                        if [ -n "$kernel_info" ]; then
                            echo "     🖥️  Kernel: $kernel_info"
                            USB_LOG+=("$(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed | $device_class | $driver | $kernel_info")
                        else
                            USB_LOG+=("$(date '+%H:%M:%S') ➕ $vendor_product | $usb_standard | $usb_speed | $device_class | $driver")
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
        
        # Hole detaillierte USB-Informationen mit lsusb -t
        detailed_info=$(get_usb_detailed_info "$bus" "$device")
        usb_standard=$(echo "$detailed_info" | cut -d'|' -f1)
        usb_speed=$(echo "$detailed_info" | cut -d'|' -f2)
        device_class=$(echo "$detailed_info" | cut -d'|' -f3)
        driver=$(echo "$detailed_info" | cut -d'|' -f4)
        
        device_count=$((device_count + 1))
        
        echo ""
        echo "📱 Gerät #$device_count: $vendor_product"
        echo "   🔗 Bus: $bus, Device: $device"
        echo "   📊 Standard: $usb_standard"
        echo "   ⚡ Geschwindigkeit: $usb_speed"
        echo "   🏷️  Klasse: $device_class"
        echo "   🔧 Treiber: $driver"
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

function show_help() {
    echo "🔍 USB-Watcher - Einfache Version mit Kernel-Device Info"
    echo "========================================================"
    echo ""
    echo "📋 VERFÜGBARE PARAMETER:"
    echo ""
    echo "  --watch-cli        Startet USB-Überwachung im Terminal"
    echo "  --list-cli         Zeigt alle USB-Geräte im Terminal"
    echo "  --help             Zeigt diese Hilfe"
    echo ""
    echo "🚀 BEISPIELE:"
    echo "  $0 --watch-cli     # USB-Watcher starten"
    echo "  $0 --list-cli      # USB-Geräte auflisten"
    echo ""
}

# Haupt-Eingabebehandlung
case "${1:-}" in
    --watch-cli)
        trap 'echo ""; echo "🛑 USB-Watcher beendet um $(date '+%H:%M:%S')"; exit 0' INT
        usb_watcher_cli
        ;;
    --list-cli)
        show_usb_list_cli
        ;;
    --help|-h|help)
        show_help
        ;;
    *)
        echo "🔍 USB-Watcher - Einfache Version"
        echo "=================================="
        echo ""
        echo "Verwenden Sie --help für alle Optionen"
        echo ""
        echo "Schnellstart:"
        echo "  $0 --watch-cli     # USB-Überwachung starten"
        echo "  $0 --list-cli      # USB-Geräte auflisten"
        ;;
esac