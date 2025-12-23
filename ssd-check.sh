#!/usr/bin/env bash
# ssd_check_safe.sh — Menu driven SSD check voor macOS en Linux
# Met handmatige disk-selectie + systeemdisk-bescherming

set -e

OS="$(uname)"
echo "🔍 SSD Check Script gestart op $OS"

SYSTEM_DISK=""

if [[ "$OS" == "Darwin" ]]; then
  SYSTEM_DISK=$(diskutil info / | grep "Device Identifier" | awk '{print $3}')
  SYSTEM_DISK="/dev/$SYSTEM_DISK"
else
  SYSTEM_DISK=$(lsblk -no pkname $(df / | tail -1 | awk '{print $1}') | head -n1)
  SYSTEM_DISK="/dev/$SYSTEM_DISK"
fi

# Functie om een disk te selecteren
function select_disk() {
  echo "👉 Beschikbare schijven:"
  if [[ "$OS" == "Darwin" ]]; then
    diskutil list
  else
    lsblk -o NAME,SIZE,MODEL
  fi
  echo ""
  read -p "Voer de disk in (bijv. /dev/disk2 of sdb): " USER_DISK

  # Normaliseer Linux input
  if [[ "$OS" != "Darwin" && "$USER_DISK" != /dev/* ]]; then
    USER_DISK="/dev/$USER_DISK"
  fi

  # Veiligheidscheck
  if [[ "$USER_DISK" == "$SYSTEM_DISK" ]]; then
    echo "❌ FOUT: je hebt je systeemdisk geselecteerd ($SYSTEM_DISK)!"
    echo "   Dat is gevaarlijk. Kies een externe SSD."
    unset USER_DISK
    return
  fi

  echo "✅ Gekozen disk: $USER_DISK"
  export USER_DISK
}

function capacity_info() {
  if [[ -z "$USER_DISK" ]]; then
    echo "⚠️ Geen disk geselecteerd. Kies eerst optie 1 in het menu."
    return
  fi

  echo "👉 Capaciteit / schijfinformatie:"
  if [[ "$OS" == "Darwin" ]]; then
    diskutil info "$USER_DISK"
  else
    sudo fdisk -l "$USER_DISK"
  fi
}

function smart_status() {
  if [[ -z "$USER_DISK" ]]; then
    echo "⚠️ Geen disk geselecteerd. Kies eerst optie 1 in het menu."
    return
  fi

  if ! command -v smartctl &>/dev/null; then
    echo "⚠️ smartctl niet geïnstalleerd."
    if [[ "$OS" == "Darwin" ]]; then
      echo "   Installeer met: brew install smartmontools"
    else
      echo "   Installeer met: sudo apt install smartmontools"
    fi
    return
  fi

  echo "👉 SMART status:"
  sudo smartctl -a "$USER_DISK"
}

function integrity_test() {
  if [[ -z "$USER_DISK" ]]; then
    echo "⚠️ Geen disk geselecteerd. Kies eerst optie 1 in het menu."
    return
  fi

  echo "⚠️ WAARSCHUWING: dit schrijft naar de gekozen disk!"
  echo "   Disk: $USER_DISK"
  read -p "Weet je zeker dat dit een externe SSD is? (ja/N): " CONFIRM
  if [[ "$CONFIRM" != "ja" ]]; then
    echo "❌ Geannuleerd."
    return
  fi

  if [[ "$OS" == "Darwin" ]]; then
    echo "⚠️ f3 is niet standaard beschikbaar op macOS."
    echo "   Tip: brew install f3"
    echo "   Daarna kun je bv. doen: f3write /Volumes/SSD && f3read /Volumes/SSD"
  else
    if ! command -v f3write &>/dev/null; then
      echo "⚠️ f3 niet geïnstalleerd. Installeer met: sudo apt install f3"
      return
    fi
    echo "👉 Integriteitstest uitvoeren..."
    read -p "Map waar je wilt testen (bijv. /mnt/ssd): " TARGET
    f3write "$TARGET"
    f3read "$TARGET"
  fi
}

# Menu loop
while true; do
  echo ""
  echo "=============================="
  echo "  SSD Check Menu (Safe Mode)"
  echo "=============================="
  echo "1) Selecteer disk"
  echo "2) Capaciteit / info"
  echo "3) SMART status"
  echo "4) Integriteitstest (f3)"
  echo "5) Exit"
  echo "=============================="
  read -p "Maak een keuze [1-5]: " CHOICE

  case $CHOICE in
    1) select_disk ;;
    2) capacity_info ;;
    3) smart_status ;;
    4) integrity_test ;;
    5) echo "👋 Tot ziens!"; exit 0 ;;
    *) echo "❌ Ongeldige keuze" ;;
  esac
done