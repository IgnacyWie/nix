#!/usr/bin/env sh

set -eu

if command -v nix >/dev/null 2>&1; then
  NIX_BIN="$(command -v nix)"
elif [ -x /nix/var/nix/profiles/default/bin/nix ]; then
  NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
else
  echo "error: nix is not available on PATH or at /nix/var/nix/profiles/default/bin/nix" >&2
  exit 127
fi

if [ -r /etc/ssl/cert.pem ]; then
  export NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-/etc/ssl/cert.pem}"
fi

NIX_FLAKE_FLAGS="--extra-experimental-features nix-command --extra-experimental-features flakes"

