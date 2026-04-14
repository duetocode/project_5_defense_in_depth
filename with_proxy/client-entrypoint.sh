#!/usr/bin/env bash
set -euo pipefail

source_dir=/certs-source
target_dir=/certs

require_file() {
  local path=$1

  if [[ ! -r "$path" ]]; then
    echo "Missing required TLS file: $path" >&2
    exit 1
  fi
}

require_file "$source_dir/client.crt"
require_file "$source_dir/client.key"
require_file "$source_dir/ca.crt"

mkdir -p "$target_dir"
chown postgres:postgres "$target_dir"
chmod 0700 "$target_dir"

cp "$source_dir/client.crt" "$target_dir/client.crt"
cp "$source_dir/client.key" "$target_dir/client.key"
cp "$source_dir/ca.crt" "$target_dir/ca.crt"

chown postgres:postgres \
  "$target_dir/client.crt" \
  "$target_dir/client.key" \
  "$target_dir/ca.crt"

chmod 0644 "$target_dir/client.crt" "$target_dir/ca.crt"
chmod 0600 "$target_dir/client.key"

exec gosu postgres "$@"