#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/niri"
LAYOUT_FILE="$CONFIG_DIR/outputs.kdl"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/niri-output-layout.lock"

has_output() {
  grep -Fq "$1" <<< "$OUTPUTS"
}

write_if_changed() {
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"

  if [[ -f "$LAYOUT_FILE" ]] && cmp -s "$tmp" "$LAYOUT_FILE"; then
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$LAYOUT_FILE"
  return 0
}

emit_old_dell_acer_layout() {
  cat <<'EOF'
output "eDP-1" {
    scale 1
    transform "normal"
    position x=640 y=1440
}

output "Dell Inc. DELL U2412M YMYH147B060S" {
    transform "90"
    scale 1
    position x=2560 y=0

    layout {
        default-column-width { proportion 1.0; }
    }
}

output "Acer Technologies CB272U 0x3131AB9A" {
    scale 1
    position x=0 y=0
}
EOF
}

emit_new_dell_acer_layout() {
  cat <<'EOF'
output "eDP-1" {
    scale 1
    transform "normal"
    position x=1152 y=1728
}

output "Acer Technologies CB272U 0x3131AB9A" {
    transform "90"
    scale 1
    position x=3072 y=0

    layout {
        default-column-width { proportion 1.0; }

        struts {
          top 600
        }
    }
}

output "Dell Inc. DELL P3225QE 1YVLB84" {
    position x=0 y=0
}
EOF
}

emit_acer_only_layout() {
  cat <<'EOF'
output "eDP-1" {
    scale 1
    transform "normal"
    position x=640 y=1440
}

output "Acer Technologies CB272U 0x3131AB9A" {
    scale 1
    position x=0 y=0
}
EOF
}

emit_new_dell_only_layout() {
  cat <<'EOF'
output "eDP-1" {
    scale 1
    transform "normal"
    position x=576 y=1728
}

output "Dell Inc. DELL P3225QE 1YVLB84" {
    scale 1.25
    position x=0 y=0
}
EOF
}

emit_laptop_only_layout() {
  cat <<'EOF'
output "eDP-1" {
    scale 1
    transform "normal"
    position x=0 y=0
}
EOF
}

apply_layout() {
  OUTPUTS="$(niri msg outputs 2>/dev/null || true)"

  if has_output "Dell Inc. DELL U2412M YMYH147B060S" && has_output "Acer Technologies CB272U 0x3131AB9A"; then
    write_if_changed < <(emit_old_dell_acer_layout)
  elif has_output "Dell Inc. DELL P3225QE 1YVLB84" && has_output "Acer Technologies CB272U 0x3131AB9A"; then
    write_if_changed < <(emit_new_dell_acer_layout)
  elif has_output "Acer Technologies CB272U 0x3131AB9A"; then
    write_if_changed < <(emit_acer_only_layout)
  elif has_output "Dell Inc. DELL P3225QE 1YVLB84"; then
    write_if_changed < <(emit_new_dell_only_layout)
  else
    write_if_changed < <(emit_laptop_only_layout)
  fi
}

apply_and_reload_if_changed() {
  if apply_layout; then
    niri validate -c "$CONFIG_DIR/config.kdl" >/dev/null && niri msg action load-config-file >/dev/null
  fi
}

case "${1:---apply}" in
  --apply)
    apply_and_reload_if_changed
    ;;
  --daemon)
    exec 9>"$LOCK_FILE"
    flock -n 9 || exit 0

    apply_and_reload_if_changed

    niri msg --json event-stream 2>/dev/null | while IFS= read -r event; do
      case "$event" in
        *OutputsChanged*|*Output*)
          sleep 0.5
          apply_and_reload_if_changed
          ;;
      esac
    done
    ;;
  *)
    echo "usage: $0 [--apply|--daemon]" >&2
    exit 2
    ;;
esac
