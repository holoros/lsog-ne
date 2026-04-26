#!/bin/bash
# Update Earthdata password in ~/.netrc after a URS password change.
# The current .netrc returns 401 from URS; this helper fixes it.

set -e
NETRC="$HOME/.netrc"

if [ ! -f "$NETRC" ]; then
  echo "No ~/.netrc; creating one."
  read -p "Earthdata username: " EU
  read -s -p "Earthdata password: " EP; echo
  cat > "$NETRC" << ENC
machine urs.earthdata.nasa.gov login $EU password $EP
ENC
  chmod 600 "$NETRC"
  echo "~/.netrc written."
  exit 0
fi

CURRENT_USER=$(awk '$1=="machine" && $2=="urs.earthdata.nasa.gov"{print $4}' "$NETRC")
echo "Current Earthdata login in .netrc: ${CURRENT_USER:-<none>}"

read -p "New Earthdata username [keep $CURRENT_USER]: " EU
EU=${EU:-$CURRENT_USER}
read -s -p "New Earthdata password: " EP; echo

# Rewrite the .netrc with the updated stanza
TMP=$(mktemp)
awk -v eu="$EU" -v ep="$EP" '
  $1=="machine" && $2=="urs.earthdata.nasa.gov" {
    printf "machine urs.earthdata.nasa.gov login %s password %s\n", eu, ep
    skipped=1; next
  }
  { print }
  END { if(!skipped) printf "machine urs.earthdata.nasa.gov login %s password %s\n", eu, ep }
' "$NETRC" > "$TMP"
mv "$TMP" "$NETRC"
chmod 600 "$NETRC"

# Also reset the cookie jar so a fresh login is performed
> "$HOME/.urs_cookies"
chmod 600 "$HOME/.urs_cookies"

echo
echo "~/.netrc updated. Test with:"
echo "  bash scripts/download_ornl2498.sh --test"
