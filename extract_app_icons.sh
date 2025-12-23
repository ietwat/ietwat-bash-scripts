#!/bin/bash

# Script: extract_app_icons.sh
# Doel: alle .icns iconen uit apps in /Applications verzamelen

# Kies doelmap
echo "Kies een map om de iconen in op te slaan:"
read -r TARGET_DIR

# Check of de map bestaat
if [ ! -d "$TARGET_DIR" ]; then
  echo "Map bestaat niet. Aanmaken..."
  mkdir -p "$TARGET_DIR"
fi

# Loop door alle apps
find /Applications -name "*.app" -type d | while read -r app; do
  # Zoek .icns bestanden binnen de app
  icns_files=$(find "$app" -name "*.icns")
  
  for icon in $icns_files; do
    # Naam van de app zonder pad en .app
    app_name=$(basename "$app" .app)
    
    # Doelbestand (zodat iconen niet overschrijven)
    target_file="$TARGET_DIR/${app_name}.icns"
    
    # Kopieer bestand
    cp "$icon" "$target_file" 2>/dev/null
    echo "Gekopieerd: $icon → $target_file"
  done
done

echo "Klaar. Alle iconen staan nu in: $TARGET_DIR"
