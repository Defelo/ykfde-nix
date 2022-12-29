#!/usr/bin/env bash

KEY_LENGTH=512
SALT_LENGTH=16
ITERATIONS=1000000

rbtohex() {
  ( od -An -vtx1 | tr -d ' \n' )
}

hextorb() {
  ( tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI'| xargs printf )
}

generate_salt() {
  salt="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"
  echo -ne "$salt\n$1"
}

derive_key() {
  read -s -p "Password: " k_user
  challenge="$(echo -n $1 | openssl dgst -binary -sha512 | rbtohex)"
  response="$(ykchalresp -$3 -x $challenge 2>/dev/null)"
  echo -n "$k_user" | pbkdf2-sha512 $(($KEY_LENGTH / 8)) $2 "$response"
}

if [[ "$1" = "generate-salt" ]] && ( [[ $# -eq 1 ]] || ( [[ $# -eq 2 ]] && [[ "$2" =~ ^[0-9]+$ ]] ) ); then
  generate_salt "${2:-$ITERATIONS}"
elif [[ "$1" = "derive-key" ]] && [[ $# -eq 3 ]] && [[ -r "$2" ]] && [[ "$3" =~ ^[12]$ ]]; then
  read -d '\n' salt iterations < "$2"
  if ! [[ "$salt" =~ ^[0-9a-fA-F]+$ ]] || ! [[ "$iterations" =~ ^[0-9]+$ ]]; then
    echo "Invalid salt file"
    exit 2
  fi
  derive_key "$salt" "$iterations" "$3"
elif [[ "$1" = "time" ]] && ( [[ $# -eq 1 ]] || ( [[ $# -eq 2 ]] && [[ "$2" =~ ^[0-9]+$ ]] ) ); then
  time echo -n "test password" | pbkdf2-sha512 $(($KEY_LENGTH / 8)) ${2:-$ITERATIONS} "a015def232c3f4318da97aacdec2107a19ced931" > /dev/null
else
  echo "Usage: ykfde generate-salt [iterations]"
  echo "       ykfde derive-key <salt-file> <slot>"
  echo "       ykfde time [iterations]"
  exit 1
fi
