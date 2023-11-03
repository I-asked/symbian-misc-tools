#!/usr/bin/env bash
set -e
#set -x

INP=${1:?Input filename needed}
shift
OUT=${1:?Output filename needed}
shift

readonly DUMMY=$(mktemp)

trap 'rm -f "${DUMMY}"' EXIT

declare -A INTERMEDIATES
INTERMEDIATES=()

declare -A SECTIONS
SECTIONS=()

trap 'rm -f "${INTERMEDIATES[@]}" "${SECTIONS[@]}"' EXIT

arm-none-symbianelf-gcc -x c "$@" -o "${DUMMY}" - <<EOF
int foo = 0;
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
    elf2e32 --e32input "${INP}" --dump "${TYPEMAP[$k]}" |grep -P '^[0-9a-f]+:' |xxd -r >"${SECTIONS[$k]}"
    arm-none-symbianelf-objcopy --update-section .text="${SECTIONS[$k]}" "${LI}" "${LO}"
    LI="${INTERMEDIATES[$k]}"
done

rm -f "${OUT}"
arm-none-symbianelf-objcopy --only-section=.text,.data "${LO}" "${OUT}"
