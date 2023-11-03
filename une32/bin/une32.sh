#!/usr/bin/env bash
set -euo pipefail

err_report () {
  echo "==> Error $2 on line $1 of une32.sh"
}
trap 'err_report $LINENO $?' ERR

INP="${1:?Input filename needed}"
shift
OUT="${1:?Output filename needed}"
shift

readonly DUMMY=$(mktemp)

trap 'rm -f "${DUMMY}"' EXIT

declare -A INTERMEDIATES
INTERMEDIATES=()

declare -A SECTIONS
SECTIONS=()

trap 'rm -f "${INTERMEDIATES[@]}" "${SECTIONS[@]}"' EXIT

arm-none-symbianelf-gcc.exe -x c "$@" -o "${DUMMY}" - <<EOF
int foo = 0;
const char *bar = "foobar";
int main(int argc, char **argv) {
  foo = argc;
  return foo;
}
EOF

INTERMEDIATES[.text]+=$(mktemp)
INTERMEDIATES[.data]+=$(mktemp)

SECTIONS[.text]+=$(mktemp)
SECTIONS[.data]+=$(mktemp)

declare -A TYPEMAP
TYPEMAP[.text]+=c
TYPEMAP[.data]+=d

LI="${DUMMY}"
for k in "${!INTERMEDIATES[@]}"; do
  LO="${INTERMEDIATES[$k]}"
  /var/lib/nokiaprefix/drive_c/Nokia/devices/Nokia_Symbian_Belle_SDK_v1.0/epoc32/tools/elf2e32.exe --e32input "${INP}" --dump "${TYPEMAP[$k]}" |grep -P '^[0-9a-f]+:' |xxd -r >"${SECTIONS[$k]}" ||:
  arm-none-symbianelf-objcopy.exe --update-section "$k"="${SECTIONS[$k]}" "${LI}" "${LO}"
  LI="${INTERMEDIATES[$k]}"
done

rm -f "${OUT}"
arm-none-symbianelf-objcopy.exe --only-section=.text,.data "${LO}" "${OUT}"
