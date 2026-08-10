#!/bin/bash -eu

fuzzer="$SRC/centl/.clusterfuzzlite/caravan_content_fuzzer.py"
package="$OUT/caravan_content_fuzzer.pkg"

pyinstaller \
  --paths "$SRC/centl" \
  --distpath "$OUT" \
  --onefile \
  --name "$(basename "$package")" \
  "$fuzzer"

cat > "$OUT/caravan_content_fuzzer" <<'EOF'
#!/bin/sh
# LLVMFuzzerTestOneInput for fuzzer detection.
this_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$this_dir/caravan_content_fuzzer.pkg" "$@"
EOF
chmod +x "$OUT/caravan_content_fuzzer"
