#!/usr/bin/env bash
set -e

# Build a signed, installable IPA.
#
# A plain `xtool dev build --ipa` produces an UNSIGNED build that iOS refuses
# to install (no provisioning profile embedded). `--sign` embeds the active
# development provisioning profile, which must include the UDID of every
# device that will install the IPA.
cd "$(dirname "$0")/.."

xtool dev build --sign --ipa "$@"

echo "Signed IPA written to xtool/greeter.ipa"
