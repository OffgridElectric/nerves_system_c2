#!/bin/bash

requires=( \
  "CONFIG_F2FS_FS=y" \
  "CONFIG_F2FS_FS_SECURITY=y" \
  "CONFIG_F2FS_FS_ENCRYPTION=y" \
  "CONFIG_VFAT_FS=y" \
  "CONFIG_DEVTMPFS=y" \
  "CONFIG_DEVTMPFS_MOUNT=y" \
  "CONFIG_SQUASHFS=y" \
  "CONFIG_TI_CPSW=y" \
  )

usage() {
    echo "Usage: $(basename $0) /path/to/config"
    exit $1
}

if test $# -lt 1; then
    usage 1
fi
config=$1
shift

total=0
pass=0
fail=0
for req in "${requires[@]}"; do
    printf "%-40s" "${req}"
    total=$(( total + 1 ))
    if grep -q "^${req}" "${config}"; then
        pass=$(( pass + 1 ))
        printf "  \033[32mPASS\033[0m\n"
    else
        fail=$(( fail + 1 ))
        printf "  \033[31mFAIL\033[0m\n"
    fi
done

printf "\n"
printf "\tPassed:   \033[32m%s\033[0m/%s\n" "${pass}" "${total}"
printf "\tFailed:   \033[31m%s\033[0m/%s\n" "${fail}" "${total}"

test ${fail} -eq 0
