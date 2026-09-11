#!/bin/bash
# Guarded macOS orchestrator for the pinned UNVR 5.1.33 -> UNAS Pro 5.1.33 setup.

if [[ -z "${UNVR_UNAS_EXECUTION_SNAPSHOT_DIR:-}" ]]; then
    snapshot_dir=$(mktemp -d /private/tmp/unvr-unas-exec.XXXXXX) || exit 1
    snapshot="$snapshot_dir/convert.sh"
    snapshot_ready=false
    for _ in 1 2 3; do
        source_hash_before=$(shasum -a 256 "$0" 2>/dev/null | awk '{print $1}') || break
        install -m 0700 "$0" "$snapshot" || break
        source_hash_after=$(shasum -a 256 "$0" 2>/dev/null | awk '{print $1}') || break
        snapshot_hash=$(shasum -a 256 "$snapshot" 2>/dev/null | awk '{print $1}') || break
        if [[ "$source_hash_before" == "$source_hash_after" &&
              "$source_hash_after" == "$snapshot_hash" ]]; then
            snapshot_ready=true
            break
        fi
    done
    if [[ "$snapshot_ready" != true ]]; then
        rm -rf -- "$snapshot_dir"
        printf 'Unable to capture a stable converter snapshot; rerun the command.\n' >&2
        exit 1
    fi
    exec env UNVR_UNAS_EXECUTION_SNAPSHOT_DIR="$snapshot_dir" "$snapshot" "$@"
fi

set -Eeuo pipefail
export LC_ALL=C
export COPYFILE_DISABLE=1
umask 077

readonly REMOTE_ENGINE_SHA256=f3af7d39dc6840cc2f773d068cdf3cdbe8cf36c84acbe169723f797fc0ebdd59
readonly UPDATE_PROFILE_BUILDER_SHA256=0bdcb6ae963239551f963080998f2864acb733c110a647db9bace7ec6e8bb6d1
readonly DEBIAN_DRIVE_CLOSURE_SHA256=52e38d9730228dc2e6632cccbcd777498450d2b79f0ebf1077fa34dec8d197f9
readonly DEBIAN_KBUILD_CLOSURE_SHA256=fb99e5bfe01f99d9f40f613e7610ec34c77a1c67c0264f74b26cc455487471f8
readonly PAYLOAD_CONTRACT_SHA256=483b83cd8e3e72c07ecbe5d81c2472cb50daa890da9f341e55f096835f765ce8
readonly UBIQUITI_DRIVE_PACKAGES_SHA256=8fdfe83b30b934cc5b00b21a9a9ec812901ac979ffd65b9985b0fd012bf31067
readonly CORE_IDENTITY_BUILDER_SHA256=806eab270b38060622a754bb0ffcf1fcb648d6b85bbfaf94cd1498ce5ab931ae
readonly CORE_5X_BUILDER_SHA256=472ab10f713242d2218069b1717b2c45ee75abce434b6ac6db51c649293895d4
readonly IDENTITY_OVERLAY_BUILDER_SHA256=c00fb9a5073d6f4c9c4a67903766cd97d0a789e628da49853eca7c191c89a84f
readonly PORTAL_BUILDER_SHA256=8554cbb7f31afd281466930a492c51a33ae1820d9b981aabb3adcaa0abb8625a
readonly STORAGE_UI_VERIFIER_SHA256=20014943e53248798094a8db40f9c84f6825db3100f4d2c561448f4890524427
readonly WSDD5_BUILDER_SHA256=215243a2b8dff1073b7810a8047e7ea24efbf37d6be2414bc334d826f2e15d2a
readonly DRIVE_STORAGE_QUERY_SHA256=dd90cb4319ae43fb15a1c3c5635f540c0cb4f138e0741c08fcab7ebc62a156c9
readonly IDENTITY_RESTORE_SHA256=4b5ae523ef7a73c78cff99c7584b4871f9f84fe88c51d4dfa1b8243d84b8782a
readonly DRIVE_RESTORE_SHA256=255c853f34d60b8ea142b7131c18a2e074fd6a7f00f89e43ff7d754c05a14647
readonly DRIVE_LAUNCHER_SHA256=28197a0032fbad95329dd5e9d4ca1f17adc5334f38561a8229ff8c5cbb9c0af3
readonly DRIVE_IDENTITY_ADAPTER_SHA256=702081e0478f2cbdd0147caef1f0c21ce8600691b2c2d9c9910626cd555759a4
readonly IDENTITY_UNIT_SHA256=11471cd6329c8482803e54a1f5a0cbbc0d972a690103fe68f4e39f29d0b5854d
readonly DRIVE_UNIT_SHA256=30e351f068f49559770c692540ec9198a729d7f131b50d00e2dc2b2345920ec6
readonly GUARDED_FWUPDATE_SHA256=e21771e55ffffd98f45990adcba6965dafd3108e443cdac141247b60095fbd75
readonly LOGICAL_UNADOPT_SHA256=65149af2ff8b52acc260f22cf72343b506274873ea6137dc991903199155524d
readonly READOPT_SSH_RESTORER_SHA256=e8ab54e705a072ddd40c09f82679fadcc7dfcdb03fccd091a5166be62f73e6d1
readonly READOPT_SSH_UNIT_SHA256=f71cf3e3839d74606989e1ba278cdd52ba37466eb662aa24f06a3775025a7977
readonly EMBEDDED_HELPERS_SHA256=434cdb43b1f046ade73f0fb72fdd7280185fa639520dfb5d8b0420ca0d884693
readonly TEMPORARY_SSH_PASSWORD=UnvrToUnasConversion1

script_dir=
remote_engine=
profile_builder=

command=install
unvr_ip=
controller_ip=
controller_site=
controller_client_mac=
controller_cleanup_mode=unresolved
unas_firmware=
unvr5_firmware=
unas5_firmware=
dry_run=false
temp_root=
execution_snapshot_dir=${UNVR_UNAS_EXECUTION_SNAPSHOT_DIR:-}
control_socket=
ssh_password=$TEMPORARY_SSH_PASSWORD
known_hosts=
api_cookie=
api_response=
api_headers=
api_csrf=
api_csrf_header=
controller_api_cookie=
controller_api_response=
controller_api_headers=
controller_api_csrf=
controller_api_csrf_header=
ui_account=
ui_account_password=
mfa_token=
spinner_pid=
spinner_label=
interrupt_prompt_active=false
interrupt_declined=false
interrupt_reenable_errexit=false
timeline_active=false
timeline_label=
timeline_sequence_started=-1
timeline_last_number=0
timeline_last_total=0
timeline_header_rewrite_safe=false
timeline_current_number=0
timeline_current_total=0
timeline_percentage_tenths=0
timeline_step_base_tenths=0
timeline_step_ceiling_tenths=0
timeline_action_index=0
timeline_action_budget=1
timeline_time_left=
temporary_update_ssh_configured=false
timeline_eta_anchor_seconds=0
timeline_eta_anchor_remaining=0
timeline_dashboard_drawn=false
timeline_dashboard_rows=12
timeline_step_titles=(
    'Create temporary UNVR ownership and secure SSH access'
    'Verify signed UNVR 5.1.33 baseline and storage-preservation state'
    'Build the hash-verified official UNAS compatibility payload'
    'Capture rollback state and install safety guards'
    'Build exact native Btrfs, Zstd and FUSE modules'
    'Install scoped UNAS Pro identity and official Drive userspace'
    'Verify UNAS services while preserving installed storage'
    'Reboot and run pre-storage health validation'
    'Complete official UNAS setup and verify the handoff'
)
captured_output=
askpass_writer_pid=
setup_checkpoint_rows=0

usage() {
    cat <<'EOF'
Usage:
  convert.sh [install] [--ip IPv4] [--controller-ip IPv4] [firmware options] [--dry-run]
  convert.sh setup-only [--ip IPv4]
  convert.sh status [--ip IPv4]
  convert.sh disarm [--ip IPv4]
  convert.sh rollback [--ip IPv4]
  convert.sh unadopt [--ip IPv4]

Runs only from macOS and operates on an unmodified four-bay UNVR. Exact UniFi
OS 5.1.33 is the deterministic conversion baseline. A different stock UNVR
version is first normalized to the pinned, signed official 5.1.33 image when
the source updater, hardware, and signed-firmware gates all pass.

install begins with a normal yes/no destructive confirmation, invokes
Ubiquiti's stock factory reset with external-storage formatting, waits for the
unconfigured UNVR to return, and then starts conversion. This permanently
erases the console configuration and ALL data on every installed SATA drive.
It also unregisters only this UNVR console from Site Manager and forgets its
stale offline client record from the original UniFi Network controller. Site
Manager may retain the now-empty site shell until Ubiquiti permits its removal;
that shell can instead be reused when adopting the converted UNAS. The Network
site itself and every other client remain untouched. The controller is detected
from the UNVR gateway; --controller-ip overrides that address when necessary.
Declining the confirmation exits without resetting or converting the console.

Authentication and privacy:
  - UI Account credentials and MFA automate normal UniFi sign-in, temporary
    console ownership, local setup, Site Manager unregistration, temporary SSH,
    automatic-update control, and exact-client cleanup when the original Network
    site is accessible.
  - The password and MFA code are held only in process memory, never written to
    disk or logs, never placed in command arguments, and cleared on exit.
  - They are sent only over HTTPS to local UniFi console/controller services and
    the Ubiquiti UI identity services used by the normal sign-in flow.
  - Private temporary session cookies and CSRF material are permission-restricted
    and deleted when the script exits.

Warranty and liability:
  - This is an unofficial community conversion and is not supported by Ubiquiti.
  - It will probably void any applicable Ubiquiti warranty.
  - The author is not liable for data loss, hardware damage, loss of service, or
    any other damages resulting from use of this script.

The installer assigns the temporary SSH password `UnvrToUnasConversion1`
through the local UniFi API and never asks the user for an SSH password. SSH is
used only for conversion and is disabled by the on-device finalizer after UNAS
setup completes.

setup-only performs only that temporary console ownership, SSH and update-
schedule configuration, then exits before firmware normalization or conversion.

Optional exact official image overrides for install:
  --unvr-5-firmware FILE     UNVR 5.1.33
  --unas-5-firmware FILE     UNAS Pro 5.1.33

install downloads (or accepts) exact official Ubiquiti firmware, extracts only
profiled userspace as data, installs Drive, builds native Btrfs/FUSE modules,
applies the scoped UNAS identity and blocks subsequent OS firmware updates. The
repository does not need to contain any firmware binaries: missing images are
downloaded directly from Ubiquiti and accepted only after exact size and
SHA-256 validation. Downloads remain private temporary files and are removed
when the installer exits. A source already on 5.1.33 performs no firmware
write. Other eligible stock UNVR versions are normalized through the console's
own signed updater, rebooted and exact-hash checked before conversion.
The direct 5.1.33 path supports zero to four installed drives. After the
confirmed reset, storage-pool creation is left to the user in the official
Drive UI. The installer validates a reboot, unregisters temporary ownership,
and asks you to complete official UNAS Pro setup in the web UI or mobile app.
Press Enter when finished. The installer checks the console's local setup
status and prompts again if setup is incomplete or cannot be verified.

rollback restores guarded software/configuration state. It deliberately does
not erase or restore the SATA storage pool or user data.

This release installs the fixed UNAS Pro 5.1.33 baseline. Automatic OS and
application updates are disabled. Control Plane OS firmware installations and
legacy prepare-os-update/arm commands are not supported. Manual Drive updates
remain subject to their existing compatibility checks; no arbitrary future
OS or Drive release is implied to be supported.

--dry-run performs exact read-only target and storage-inventory gates. It downloads,
installs, patches, stops, formats, reboots, or persists nothing.
EOF
}

spinner_clear() {
    local had_errexit=false
    [[ $- == *e* ]] && had_errexit=true
    set +e
    if [[ -n "$spinner_pid" ]]; then
        kill "$spinner_pid" >/dev/null 2>&1
        wait "$spinner_pid" >/dev/null 2>&1
        spinner_pid=
        if [[ -t 1 && ${TERM:-dumb} != dumb && "$timeline_active" == true &&
              "$timeline_dashboard_drawn" == true && "$timeline_header_rewrite_safe" == true ]]; then
            timeline_refresh_current
        elif [[ -t 1 ]]; then
            printf '\r\033[2K'
        fi
    fi
    if [[ "$had_errexit" == true ]]; then set -e; else set +e; fi
}

spinner_start() {
    spinner_clear
    spinner_label=$*
    timeline_advance_action
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        (
            local stop_requested=false
            trap 'stop_requested=true' TERM INT
            while [[ "$stop_requested" != true ]]; do
                for frame in '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'; do
                    [[ "$stop_requested" != true ]] || break
                    if [[ "$timeline_active" == true && "$timeline_header_rewrite_safe" == true ]]; then
                        timeline_animate_processing_frame "$frame" "$spinner_label"
                    else
                        printf '\r\033[2K\033[1;34m%s\033[0m %s' "$frame" "$spinner_label"
                    fi
                    sleep 0.12 || true
                done
            done
        ) &
        spinner_pid=$!
    else
        printf '~ %s\n' "$spinner_label"
    fi
}

spinner_stop() {
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        spinner_clear
    fi
    spinner_label=
}

format_time_left() {
    local seconds=$1 hours minutes
    if (( seconds < 60 )); then
        printf '1m remaining'
    elif (( seconds < 3600 )); then
        printf '%dm remaining' "$(( (seconds + 59) / 60 ))"
    else
        hours=$((seconds / 3600))
        minutes=$(((seconds % 3600 + 59) / 60))
        if (( minutes == 60 )); then
            hours=$((hours + 1))
            minutes=0
        fi
        if (( minutes > 0 )); then
            printf '%dh %dm remaining' "$hours" "$minutes"
        else
            printf '%dh remaining' "$hours"
        fi
    fi
}

timeline_standard_step_seconds() {
    case "$1" in
        1) printf '720' ;; # reset, two setup sessions, authentication, and SSH
        2) printf '30'  ;; # baseline validation
        3) printf '240' ;; # download and build the 2.1 GB compatibility payload
        4) printf '60'  ;; # rollback capture and guards
        5) printf '360' ;; # native module build and storage-state preparation
        6) printf '240' ;; # identity and Drive package installation
        7) printf '30'  ;; # pre-storage service validation
        8) printf '180' ;; # first reboot and validation
        9) printf '240' ;; # handoff, second reboot, and discovery validation
        *) printf '60'  ;;
    esac
}

timeline_calculated_remaining_seconds() {
    local current_weight future=0 span completed_within remaining_current step
    current_weight=$(timeline_standard_step_seconds "$timeline_current_number")
    for ((step = timeline_current_number + 1; step <= 9; step++)); do
        future=$((future + $(timeline_standard_step_seconds "$step")))
    done
    span=$((timeline_step_ceiling_tenths - timeline_step_base_tenths))
    completed_within=$((timeline_percentage_tenths - timeline_step_base_tenths))
    if (( span > 0 )); then
        remaining_current=$((current_weight * (span - completed_within) / span))
    else
        remaining_current=$current_weight
    fi
    printf '%d' "$((remaining_current + future))"
}

timeline_reset_eta_anchor() {
    timeline_eta_anchor_seconds=$SECONDS
    timeline_eta_anchor_remaining=$(timeline_calculated_remaining_seconds)
}

timeline_refresh_time_left() {
    local elapsed remaining
    elapsed=$((SECONDS - timeline_eta_anchor_seconds))
    remaining=$((timeline_eta_anchor_remaining - elapsed))
    (( remaining >= 60 )) || remaining=60
    timeline_time_left=$(format_time_left "$remaining")
}

timeline_action_budget_for() {
    local current=$1 total=$2 label=$3
    if (( current == 1 )); then
        printf '20'
    else
        case "$current" in
            2) printf '1' ;;
            3) printf '2' ;;
            4) printf '3' ;;
            5) printf '5' ;;
            6) printf '2' ;;
            7) printf '1' ;;
            8) printf '3' ;;
            9) printf '5' ;;
            *) printf '3' ;;
        esac
    fi
}

timeline_percentage_text() {
    if (( timeline_percentage_tenths % 10 == 0 )); then
        printf '%d' "$((timeline_percentage_tenths / 10))"
    else
        printf '%d.%d' "$((timeline_percentage_tenths / 10))" "$((timeline_percentage_tenths % 10))"
    fi
}

timeline_render_progress() {
    local percentage_text filled column bar_width=24
    if (( timeline_percentage_tenths >= 1000 )); then
        timeline_time_left='0m remaining'
    else
        timeline_refresh_time_left
    fi
    percentage_text=$(timeline_percentage_text)
    filled=$((timeline_percentage_tenths * bar_width / 1000))
    printf '\r\033[2K'
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        for ((column = 0; column < bar_width; column++)); do
            if (( column < filled )); then
                printf '\033[2;37m█\033[0m'
            else
                printf '\033[2;90m░\033[0m'
            fi
        done
        printf ' '
        printf '\033[2;37m%s%% Complete\033[0m' "$percentage_text"
        printf '\033[2;90m  %s\033[0m\n' "$timeline_time_left"
    else
        for ((column = 0; column < bar_width; column++)); do
            if (( column < filled )); then printf '#'; else printf '-'; fi
        done
        printf ' %s%% Complete  %s\n' "$percentage_text" "$timeline_time_left"
    fi
}

timeline_render_step_row() {
    local step=$1 active_frame=${2:-⠋} title
    title=${timeline_step_titles[$((step - 1))]}
    printf '\r\033[2K'
    if (( step < timeline_current_number )); then
        if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
            printf '\033[1;32m✓\033[0m\033[2;37m  %s\033[0m\n' "$title"
        else
            printf '✓  %s\n' "$title"
        fi
    elif (( step == timeline_current_number )) && [[ "$timeline_active" == true ]]; then
        if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
            printf '\033[1;97m%s  %s\033[0m\n' "$active_frame" "$title"
        else
            printf '~  %s\n' "$title"
        fi
    else
        if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
            printf '\033[2;37m○  %s\033[0m\n' "$title"
        else
            printf '○  %s\n' "$title"
        fi
    fi
}

timeline_render_dashboard() {
    local active_frame=${1:-⠋} step child_rendered=false
    if [[ "$timeline_dashboard_drawn" == true ]]; then
        printf '\r\033[2K\033[%dA\r' "$timeline_dashboard_rows"
    else
        printf '\n'
    fi
    timeline_render_progress
    printf '\r\033[2K\n'
    for ((step = 1; step <= 9; step++)); do
        timeline_render_step_row "$step" "$active_frame"
        if (( step == timeline_current_number )) && [[ "$timeline_active" == true ]]; then
            printf '\r\033[2K\n'
            child_rendered=true
        fi
    done
    if [[ "$child_rendered" == false ]]; then
        printf '\r\033[2K\n'
    fi
    timeline_dashboard_drawn=true
}

timeline_animate_processing_frame() {
    local frame=$1 label=$2 distance
    [[ "$timeline_active" == true && "$timeline_header_rewrite_safe" == true ]] || return 0
    [[ -t 1 && ${TERM:-dumb} != dumb ]] || return 0
    (( timeline_current_number >= 1 && timeline_current_number <= 9 )) || return 0
    distance=$((timeline_dashboard_rows - timeline_current_number - 1))
    printf '\0337\r\033[%dA\033[1;97m%s\033[0m\033[1B\r\033[2K' \
        "$distance" "$frame"
    printf '\033[2;37m╰─ \033[0m\033[1;34m%s\033[0m  %s\0338' "$frame" "$label"
}

timeline_refresh_current() {
    [[ "$timeline_active" == true && "$timeline_header_rewrite_safe" == true ]] || return 0
    [[ -t 1 && ${TERM:-dumb} != dumb ]] || return 0
    timeline_render_dashboard
}

timeline_advance_action() {
    local span advance next
    [[ "$timeline_active" == true && "$timeline_header_rewrite_safe" == true ]] || return 0
    [[ -t 1 && ${TERM:-dumb} != dumb ]] || return 0
    timeline_action_index=$((timeline_action_index + 1))
    span=$((timeline_step_ceiling_tenths - timeline_step_base_tenths))
    advance=$((span * timeline_action_index / (timeline_action_budget + 1)))
    next=$((timeline_step_base_tenths + advance))
    if (( next >= timeline_step_ceiling_tenths )); then
        next=$((timeline_step_ceiling_tenths - 1))
    fi
    if (( next > timeline_percentage_tenths )); then
        timeline_percentage_tenths=$next
        timeline_reset_eta_anchor
        timeline_refresh_current
    fi
}

timeline_complete_current() {
    local completed_through
    [[ "$timeline_active" == true ]] || return 0
    spinner_clear
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        completed_through=$timeline_current_number
        timeline_percentage_tenths=$timeline_step_ceiling_tenths
        timeline_current_number=$((completed_through + 1))
        timeline_active=false
        timeline_render_dashboard
    else
        printf '✓  %s\n' "$timeline_label"
    fi
    timeline_active=false
    timeline_header_rewrite_safe=false
}

timeline_step() {
    local current=$1 total=$2 label=$3 completed
    (( total == 9 )) || die 'internal timeline must contain exactly nine steps'
    if [[ "$timeline_active" == true && "$current" -eq "$timeline_current_number" && "$total" -eq "$timeline_current_total" ]]; then
        timeline_refresh_current
        return 0
    fi
    if (( timeline_sequence_started < 0 || current <= 1 || total != timeline_last_total || current <= timeline_last_number )); then
        timeline_sequence_started=$SECONDS
    fi
    completed=$((current - 1))
    timeline_active=true
    timeline_label=${timeline_step_titles[$completed]}
    timeline_current_number=$current
    timeline_current_total=$total
    timeline_step_base_tenths=$((completed * 1000 / total))
    timeline_step_ceiling_tenths=$((current * 1000 / total))
    timeline_percentage_tenths=$timeline_step_base_tenths
    timeline_action_index=0
    timeline_action_budget=$(timeline_action_budget_for "$current" "$total" "$label")
    timeline_last_number=$current
    timeline_last_total=$total
    timeline_header_rewrite_safe=true
    timeline_reset_eta_anchor
    timeline_render_dashboard
}

log() {
    [[ "$timeline_active" != true ]] || timeline_header_rewrite_safe=false
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[2;37m%s\033[0m\n' "$*"
    else
        printf '%s\n' "$*"
    fi
}
die() { spinner_clear; printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
sha() { shasum -a 256 "$1" | awk '{print $1}'; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "required macOS command not found: $1"; }

timeline_input_prompt_begin() {
    local label=$1 child_label
    child_label=${1%: }
    timeline_animate_processing_frame '⠋' "Waiting for $child_label"
    printf '\n\033[1;33m%s\033[0m' "$label"
}

timeline_input_prompt_finish() {
    printf '\r\033[2K\033[1A\r\033[2K\033[1A\r'
    timeline_render_dashboard
}

timeline_read_input() {
    local label=$1 variable=$2 secret=$3 value='' rc read_rc opener_pid input_fifo
    input_fifo="$temp_root/input.fifo"
    timeline_input_prompt_begin "$label"
    rm -f -- "$input_fifo"
    mkfifo -m 600 "$input_fifo" || die 'could not create private terminal input channel'
    (: > "$input_fifo") &
    opener_pid=$!
    exec 8<"$input_fifo" || die 'could not open private terminal input channel'
    wait "$opener_pid" || die 'could not initialize private terminal input channel'
    exec 9>"$input_fifo" || die 'could not open private terminal result channel'
    set +e
    python3 -c '
import os
import select
import sys
import termios

label = sys.argv[1]
secret = sys.argv[2] == "true"
current_step = int(sys.argv[3])
dashboard_rows = int(sys.argv[4])
child_label = "Waiting for " + label.rstrip().rstrip(":")
frames = ("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
value = bytearray()
frame_index = 0
escape_sequence = False
input_fd = sys.stdin.fileno()
output_fd = sys.stderr.fileno()
result_fd = 9
original = termios.tcgetattr(input_fd)
updated = termios.tcgetattr(input_fd)
columns = os.get_terminal_size(output_fd).columns
updated[3] &= ~(termios.ICANON | termios.ECHO)
updated[6][termios.VMIN] = 0
updated[6][termios.VTIME] = 0

def visible_value():
    if secret:
        return ""
    text = value.decode("utf-8", "replace")
    limit = min(36, max(4, columns - len(label) - 1))
    return text if len(text) <= limit else "…" + text[-(limit - 1):]

def redraw(frame):
    distance = dashboard_rows - current_step
    line = (
        f"\0337\r\033[{distance}A\033[1;97m{frame}\033[0m"
        f"\033[1B\r\033[2K\033[2;37m╰─ \033[0m"
        f"\033[1;34m{frame}\033[0m  {child_label}\0338"
        f"\r\033[2K\033[1;33m{label}\033[0m"
    )
    shown = visible_value()
    if shown:
        line += f"\033[0;37m{shown}\033[0m"
    os.write(output_fd, line.encode("utf-8"))

try:
    termios.tcsetattr(input_fd, termios.TCSANOW, updated)
    redraw(frames[frame_index])
    finished = False
    while not finished:
        readable, _, _ = select.select([input_fd], [], [], 0.12)
        if readable:
            chunk = os.read(input_fd, 64)
            for byte in chunk:
                if escape_sequence:
                    if 64 <= byte <= 126:
                        escape_sequence = False
                    continue
                if byte == 27:
                    escape_sequence = True
                elif byte in (10, 13):
                    finished = True
                    break
                elif byte in (8, 127):
                    if value:
                        value.pop()
                        while value and (value[-1] & 0xC0) == 0x80:
                            value.pop()
                elif byte == 21:
                    value.clear()
                elif byte >= 32:
                    if len(value) < 512:
                        value.append(byte)
        frame_index = (frame_index + 1) % len(frames)
        redraw(frames[frame_index])
except KeyboardInterrupt:
    sys.exit(130)
finally:
    termios.tcsetattr(input_fd, termios.TCSANOW, original)

os.write(result_fd, bytes(value) + b"\0")
' "$label" "$secret" "$timeline_current_number" "$timeline_dashboard_rows"
    rc=$?
    exec 9>&-
    value=
    read_rc=1
    if [[ "$rc" -eq 0 ]]; then
        IFS= read -r -d '' value <&8
        read_rc=$?
    fi
    exec 8<&-
    rm -f -- "$input_fifo"
    set -e
    if [[ "$rc" -ne 0 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        timeline_read_input "$label" "$variable" "$secret"
        return
    fi
    [[ "$rc" -eq 0 && "$read_rc" -eq 0 ]] || die 'terminal input failed'
    printf -v "$variable" '%s' "$value"
    printf '\n'
    timeline_input_prompt_finish
}

prompt_value() {
    local label=$1 variable=$2
    timeline_advance_action
    if [[ -t 1 && ${TERM:-dumb} != dumb && "$timeline_active" == true &&
          "$timeline_dashboard_drawn" == true && "$timeline_header_rewrite_safe" == true ]]; then
        timeline_read_input "$label" "$variable" false
        return
    fi
    printf '\n'
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[1;33m%s\033[0m' "$label"
    else
        printf '%s' "$label"
    fi
    IFS= read -r "${variable?}"
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[2A\r\033[J'
    fi
}

prompt_secret() {
    local label=$1 variable=$2
    timeline_advance_action
    if [[ -t 1 && ${TERM:-dumb} != dumb && "$timeline_active" == true &&
          "$timeline_dashboard_drawn" == true && "$timeline_header_rewrite_safe" == true ]]; then
        timeline_read_input "$label" "$variable" true
        return
    fi
    printf '\n'
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[1;33m%s\033[0m' "$label"
    else
        printf '%s' "$label"
    fi
    IFS= read -r -s "${variable?}"
    printf '\n'
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[2A\r\033[J'
    fi
}

print_conversion_title() {
    printf '\n'
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[1;30;47m UniFi UNVR to UNAS Pro Conversion \033[0m\n\n'
    else
        printf '=== UniFi UNVR to UNAS Pro Conversion ===\n\n'
    fi
}

print_target_summary() {
    printf '\n'
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '\033[1;97mTarget: UNVR\033[0m\n'
        printf '\033[1;97mIP: %s\033[0m\n' "$unvr_ip"
        printf '\033[2;37mzero-to-four installed drives will be preserved until UNAS setup.\033[0m\n'
    else
        printf 'Target: UNVR\n'
        printf 'IP: %s\n' "$unvr_ip"
        printf 'zero-to-four installed drives will be preserved until UNAS setup.\n'
    fi
    printf '\n'
}

reset_box_line() {
    printf '│ %-76.76s │\n' "$1"
}

print_box_border() {
    local left=$1 right=$2 column
    printf '%s' "$left"
    for ((column = 0; column < 78; column++)); do
        printf '─'
    done
    printf '%s\n' "$right"
}

reset_box_heading() {
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '│ \033[1m%-76s\033[0m │\n' "$1"
    else
        reset_box_line "$1"
    fi
}

reset_box_colored_heading() {
    local color=$1 label=$2
    if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
        printf '│ \033[1;%sm%-76s\033[0m │\n' "$color" "$label"
    else
        reset_box_line "$label"
    fi
}

print_destructive_reset_box() {
    print_box_border '┌' '┐'
    reset_box_colored_heading 31 'What will be erased'
    reset_box_line '  - UNVR console configuration'
    reset_box_line '  - All data on every installed SATA drive'
    reset_box_line '  - RAID metadata, storage pools, shares, recordings, and backups'
    reset_box_line ''
    reset_box_heading 'What will be preserved'
    reset_box_line '  - The Network site and all other controller devices and clients'
    reset_box_line ''
    reset_box_colored_heading 32 'What will not be modified'
    reset_box_line '  - Recovery kernel and recovery environment'
    reset_box_line '  - Physical hardware identity'
    reset_box_line ''
    reset_box_heading 'Firmware normalization'
    reset_box_line '  - Other supported OS versions are normalized to signed UNVR 5.1.33'
    reset_box_line '  - The stock updater may replace UNVR U-Boot and reset its environment'
    reset_box_line '  - Official firmware images are hash-verified and never patched'
    reset_box_line ''
    reset_box_heading 'Console cleanup'
    reset_box_line '  - Unregisters this UNVR console from Site Manager'
    reset_box_line '  - Forgets only this UNVR client when its Network site is accessible'
    reset_box_line '  - An empty Site Manager shell may remain and can be reused for UNAS'
    reset_box_line ''
    reset_box_colored_heading 34 'Authentication and privacy'
    reset_box_line '  - Automates normal UI Account sign-in, MFA, and local console setup'
    reset_box_line '  - Creates temporary ownership, enables SSH, and disables auto-updates'
    reset_box_line '  - Authenticates the original Network controller for client cleanup'
    reset_box_line '  - Unregisters temporary ownership before official UNAS setup'
    reset_box_line '  - Password and MFA code stay only in memory and are cleared on exit'
    reset_box_line '  - Never written to disk, logs, command arguments, or the payload'
    reset_box_line '  - Sent only over HTTPS to local UniFi services and Ubiquiti UI'
    reset_box_line '    identity services used by the normal sign-in flow'
    reset_box_line '  - Private temporary session cookies are deleted when the script exits'
    reset_box_line ''
    reset_box_colored_heading 33 'Warranty and liability'
    reset_box_line '  - This unofficial conversion is not supported by Ubiquiti'
    reset_box_line '  - It will probably void any applicable Ubiquiti warranty'
    reset_box_line '  - The author is not liable for data loss, hardware damage, service loss,'
    reset_box_line '    or any other damages resulting from use of this script'
    print_box_border '└' '┘'
}

cleanup() {
    local rc=$?
    set +e
    spinner_clear
    if [[ "$temporary_update_ssh_configured" == true ]]; then
        if ! disable_update_ssh >/dev/null 2>&1; then
            printf '\nTemporary SSH cleanup failed. Disable SSH in UniFi Control Plane.\n' >&2
            rc=1
        fi
    fi
    if [[ -n "$askpass_writer_pid" ]]; then
        kill "$askpass_writer_pid" >/dev/null 2>&1 || true
        wait "$askpass_writer_pid" >/dev/null 2>&1 || true
        askpass_writer_pid=
    fi
    if [[ -n "$control_socket" && -S "$control_socket" ]]; then
        ssh -S "$control_socket" -O exit "root@$unvr_ip" >/dev/null 2>&1
    fi
    if [[ -n "$temp_root" && -d "$temp_root" && "$temp_root" == /private/tmp/unvr-unas-installer.* ]]; then
        rm -rf -- "$temp_root"
    fi
    if [[ -n "$execution_snapshot_dir" && -d "$execution_snapshot_dir" &&
          "$execution_snapshot_dir" == /private/tmp/unvr-unas-exec.* ]]; then
        rm -rf -- "$execution_snapshot_dir"
    fi
    ssh_password=
    ui_account=
    ui_account_password=
    mfa_token=
    controller_client_mac=
    controller_site=
    controller_cleanup_mode=unresolved
    exit "$rc"
}

reenable_errexit_after_interrupt() {
    if [[ "$interrupt_reenable_errexit" == true && "${FUNCNAME[1]:-}" != confirm_interrupt ]]; then
        interrupt_reenable_errexit=false
        trap - DEBUG
        set -e
    fi
}

confirm_interrupt() {
    local answer='' resume_label had_errexit=false
    resume_label=$spinner_label
    if [[ "$interrupt_prompt_active" == true ]]; then
        return 0
    fi
    interrupt_prompt_active=true
    [[ $- == *e* ]] && had_errexit=true
    set +e
    spinner_clear
    while :; do
        printf '\n\033[1;33mAre you sure you want to stop the conversion? [y/N] \033[0m'
        IFS= read -r answer
        case "$answer" in
            y|Y|yes|YES|Yes)
                trap - INT
                exit 130
                ;;
            ''|n|N|no|NO|No)
                interrupt_declined=true
                interrupt_prompt_active=false
                if [[ -t 1 && ${TERM:-dumb} != dumb && "$timeline_dashboard_drawn" == true ]]; then
                    printf '\033[H\033[2J\033[3J'
                    print_conversion_title
                    print_target_summary
                    timeline_dashboard_drawn=false
                    timeline_render_dashboard
                else
                    printf '\n\033[2;37mContinuing conversion.\033[0m\n'
                fi
                if [[ -n "$resume_label" ]]; then
                    if (( timeline_action_index > 0 )); then
                        timeline_action_index=$((timeline_action_index - 1))
                    fi
                    spinner_start "$resume_label"
                fi
                if [[ "$had_errexit" == true ]]; then
                    interrupt_reenable_errexit=true
                    trap reenable_errexit_after_interrupt DEBUG
                else
                    set +e
                fi
                return 0
                ;;
            *) printf '\nPlease answer yes or no.\n' ;;
        esac
    done
}

trap cleanup EXIT HUP TERM
trap confirm_interrupt INT

validate_ipv4() {
    local ip=$1 old_ifs=$IFS octet decimal count=0 first=
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    IFS=.
    for octet in $ip; do
        count=$((count + 1))
        [[ ${#octet} -eq 1 || "$octet" != 0* ]] || { IFS=$old_ifs; return 1; }
        decimal=$((10#$octet))
        [[ "$decimal" -ge 0 && "$decimal" -le 255 ]] || { IFS=$old_ifs; return 1; }
        [[ -n "$first" ]] || first=$decimal
    done
    IFS=$old_ifs
    [[ "$count" -eq 4 && "$first" -ge 1 && "$first" -le 223 && "$first" -ne 127 ]]
}

parse_args() {
    if [[ $# -gt 0 ]]; then
        case "$1" in
            prepare-os-update|arm-stage1|arm-stage2)
                die 'OS updates are not supported by this fixed UNAS Pro 5.1.33 release' ;;
            install|setup-only|status|disarm|rollback|unadopt) command=$1; shift ;;
        esac
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ip) [[ $# -ge 2 ]] || die '--ip requires a value'; unvr_ip=$2; shift 2 ;;
            --controller-ip) [[ $# -ge 2 ]] || die '--controller-ip requires a value'; controller_ip=$2; shift 2 ;;
            --unas-firmware) die 'use --unas-5-firmware with the exact UNAS Pro 5.1.33 image' ;;
            --unvr-5-firmware) [[ $# -ge 2 ]] || die '--unvr-5-firmware requires a file'; unvr5_firmware=$2; shift 2 ;;
            --unas-5-firmware) [[ $# -ge 2 ]] || die '--unas-5-firmware requires a file'; unas5_firmware=$2; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "unknown argument: $1" ;;
        esac
    done
    [[ "$command" == install || ( -z "$unas_firmware" && -z "$unvr5_firmware" && -z "$unas5_firmware" ) ]] || die 'firmware file options are only valid with install'
    [[ "$command" == install || -z "$controller_ip" ]] || die '--controller-ip is only valid with install'
    [[ "$command" == install || "$dry_run" == false ]] || die '--dry-run is only valid with install'
}

check_macos() {
    [[ $(uname -s) == Darwin ]] || die 'this orchestrator currently supports macOS only'
    [[ ${#TEMPORARY_SSH_PASSWORD} -ge 12 && ${#TEMPORARY_SSH_PASSWORD} -le 128 &&
       "$TEMPORARY_SSH_PASSWORD" =~ [A-Z] && "$TEMPORARY_SSH_PASSWORD" =~ [a-z] &&
       "$TEMPORARY_SSH_PASSWORD" =~ [0-9] ]] \
        || die 'internal temporary SSH password violates the UniFi OS policy'
    require_command ssh
    require_command shasum
    require_command mkfifo
    require_command curl
    require_command nc
    require_command jq
    require_command awk
    require_command sed
    require_command cut
    require_command tr
    require_command stat
    require_command mktemp
    require_command ar
    require_command tar
    require_command gzip
    require_command unsquashfs
    require_command xz
    require_command node
    require_command python3
    [[ -f "$remote_engine" ]] || die "missing remote engine: $remote_engine"
    [[ -x "$profile_builder" ]] || die "missing update profile builder: $profile_builder"
    [[ $(sha "$remote_engine") == "$REMOTE_ENGINE_SHA256" ]] || die 'remote engine hash mismatch'
    [[ $(sha "$profile_builder") == "$UPDATE_PROFILE_BUILDER_SHA256" ]] || die 'update profile builder hash mismatch'
    [[ $(sha "$script_dir/debian_drive_closure.tsv") == "$DEBIAN_DRIVE_CLOSURE_SHA256" ]] || die 'immutable Debian closure manifest hash mismatch'
    [[ $(sha "$script_dir/debian_kbuild_closure.tsv") == "$DEBIAN_KBUILD_CLOSURE_SHA256" ]] || die 'immutable kernel-build manifest hash mismatch'
    [[ $(sha "$script_dir/verify_payload_contract.py") == "$PAYLOAD_CONTRACT_SHA256" ]] || die 'payload verifier hash mismatch'
    [[ $(sha "$script_dir/ubiquiti_drive_packages.tsv") == "$UBIQUITI_DRIVE_PACKAGES_SHA256" ]] || die 'immutable Ubiquiti package manifest hash mismatch'
    [[ $(sha "$script_dir/build_core_unaspro_identity_patch.js") == "$CORE_IDENTITY_BUILDER_SHA256" ]] || die 'Core identity builder hash mismatch'
    [[ $(sha "$script_dir/build_core_5x_unaspro_patch.js") == "$CORE_5X_BUILDER_SHA256" ]] || die 'Core 5.x builder hash mismatch'
    [[ $(sha "$script_dir/build_5x_identity_overlays.py") == "$IDENTITY_OVERLAY_BUILDER_SHA256" ]] || die 'identity overlay builder hash mismatch'
    [[ $(sha "$script_dir/patch_portal_unaspro_manifest.js") == "$PORTAL_BUILDER_SHA256" ]] || die 'portal identity builder hash mismatch'
    [[ $(sha "$script_dir/verify_storage_ui_contract.js") == "$STORAGE_UI_VERIFIER_SHA256" ]] || die 'storage UI contract verifier hash mismatch'
    [[ $(sha "$script_dir/build_wsdd_5x_debs_macos.sh") == "$WSDD5_BUILDER_SHA256" ]] || die 'UNAS 5.x wsdd builder hash mismatch'
    [[ $(sha "$script_dir/query_drive_storage_state.js") == "$DRIVE_STORAGE_QUERY_SHA256" ]] || die 'Drive storage v2 query hash mismatch'
    [[ $(sha "$script_dir/ensure_unas_identity_at_boot.sh") == "$IDENTITY_RESTORE_SHA256" ]] || die 'identity restore hash mismatch'
    [[ $(sha "$script_dir/restore_drive_after_base_update.sh") == "$DRIVE_RESTORE_SHA256" ]] || die 'Drive restore hash mismatch'
    [[ $(sha "$script_dir/unifi-drive-launcher") == "$DRIVE_LAUNCHER_SHA256" ]] || die 'Drive launcher hash mismatch'
    [[ $(sha "$script_dir/unifi-drive-ubnt-tools") == "$DRIVE_IDENTITY_ADAPTER_SHA256" ]] || die 'Drive identity adapter hash mismatch'
    [[ $(sha "$script_dir/unvr-unas-identity-restore.service") == "$IDENTITY_UNIT_SHA256" ]] || die 'identity restore unit hash mismatch'
    [[ $(sha "$script_dir/unvr-unas-drive-restore.service") == "$DRIVE_UNIT_SHA256" ]] || die 'Drive restore unit hash mismatch'
    [[ $(sha "$script_dir/guarded-fwupdate") == "$GUARDED_FWUPDATE_SHA256" ]] || die 'guarded updater hash mismatch'
    [[ $(sha "$script_dir/logical_unadopt.sh") == "$LOGICAL_UNADOPT_SHA256" ]] || die 'logical unadoption helper hash mismatch'
    [[ $(sha "$script_dir/readopt_ssh_restorer.sh") == "$READOPT_SSH_RESTORER_SHA256" ]] || die 'readoption finalizer hash mismatch'
    [[ $(sha "$script_dir/unvr-unas-readopt-ssh.service") == "$READOPT_SSH_UNIT_SHA256" ]] || die 'readoption finalizer unit hash mismatch'
}

materialize_embedded_helpers() {
    local archive="$temp_root/embedded-helpers.tar.gz" member
    script_dir="$temp_root/helpers"
    install -d -m 0700 "$script_dir"
    base64 -D > "$archive" <<'UNVR_UNAS_EMBEDDED_HELPERS'
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
6+fr5+vnP+Dzf6BM2PQAQAYA
UNVR_UNAS_EMBEDDED_HELPERS
    [[ "$(sha "$archive")" == "$EMBEDDED_HELPERS_SHA256" ]] \
        || die 'embedded helper payload hash mismatch'
    while IFS= read -r member; do
        [[ "$member" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
            || die 'embedded helper payload contains an unsafe path'
    done < <(tar -tzf "$archive")
    tar -xzf "$archive" -C "$script_dir" --no-same-owner
    chmod 0755 \
        "$script_dir/unvr_unas_remote.sh" \
        "$script_dir/build_update_profiles_macos.sh" \
        "$script_dir/build_wsdd_5x_debs_macos.sh" \
        "$script_dir/ensure_unas_identity_at_boot.sh" \
        "$script_dir/restore_drive_after_base_update.sh" \
        "$script_dir/unifi-drive-launcher" \
        "$script_dir/unifi-drive-ubnt-tools" \
        "$script_dir/guarded-fwupdate" \
        "$script_dir/logical_unadopt.sh" \
        "$script_dir/readopt_ssh_restorer.sh"
    remote_engine="$script_dir/unvr_unas_remote.sh"
    profile_builder="$script_dir/build_update_profiles_macos.sh"
}

prompt_ip() {
    if [[ -z "$unvr_ip" ]]; then
        prompt_value 'UNVR IPv4 address: ' unvr_ip
    fi
    validate_ipv4 "$unvr_ip" || die 'invalid IPv4 address'
    if [[ -n "$controller_ip" ]]; then
        validate_ipv4 "$controller_ip" || die 'invalid UniFi Network controller IPv4 address'
        [[ "$controller_ip" != "$unvr_ip" ]] || die 'the Network controller and UNVR cannot use the same address'
    fi
}

prompt_ssh_password() {
    ssh_password=$TEMPORARY_SSH_PASSWORD
}

public_system() {
    curl -ksS --connect-timeout 10 --max-time 30 "https://$unvr_ip/api/system"
}

local_api_request() {
    local method=$1 path=$2 status csrf_token new_csrf curl_rc
    if [[ -s "$api_csrf" ]]; then
        IFS= read -r csrf_token < "$api_csrf"
    fi
    set +e
    if [[ -n "$csrf_token" ]]; then
        printf 'X-CSRF-Token: %s\n' "$csrf_token" > "$api_csrf_header"
        chmod 0600 "$api_csrf_header"
        status=$(curl -ksS \
            --connect-timeout 10 \
            --max-time "${local_api_timeout:-900}" \
            -b "$api_cookie" \
            -c "$api_cookie" \
            -D "$api_headers" \
            -X "$method" \
            -H 'Content-Type: application/json' \
            -H "Origin: https://$unvr_ip" \
            -H "Referer: https://$unvr_ip/" \
            -H "@$api_csrf_header" \
            --data-binary @- \
            -o "$api_response" \
            -w '%{http_code}' \
            "https://$unvr_ip$path" 2>/dev/null)
        curl_rc=$?
    else
        rm -f -- "$api_csrf_header"
        status=$(curl -ksS \
            --connect-timeout 10 \
            --max-time "${local_api_timeout:-900}" \
            -b "$api_cookie" \
            -c "$api_cookie" \
            -D "$api_headers" \
            -X "$method" \
            -H 'Content-Type: application/json' \
            -H "Origin: https://$unvr_ip" \
            -H "Referer: https://$unvr_ip/" \
            --data-binary @- \
            -o "$api_response" \
            -w '%{http_code}' \
            "https://$unvr_ip$path" 2>/dev/null)
        curl_rc=$?
    fi
    set -e
    if [[ "$curl_rc" -ne 0 ]]; then
        printf '000'
        return 0
    fi
    new_csrf=
    if [[ -f "$api_headers" ]]; then
        new_csrf=$(awk '
            tolower($1) == "x-csrf-token:" ||
            tolower($1) == "x-updated-csrf-token:" ||
            tolower($1) == "x-expected-csrf-token:" {
                sub(/^[^:]+:[[:space:]]*/, "")
                sub(/\r$/, "")
                token=$0
            }
            END { print token }
        ' "$api_headers")
    fi
    if [[ -n "$new_csrf" ]]; then
        printf '%s\n' "$new_csrf" > "$api_csrf"
        chmod 0600 "$api_csrf"
    fi
    printf '%s' "$status"
}

controller_api_request() {
    local method=$1 path=$2
    local local_api_timeout=30
    local unvr_ip=$controller_ip
    local api_cookie=$controller_api_cookie
    local api_response=$controller_api_response
    local api_headers=$controller_api_headers
    local api_csrf=$controller_api_csrf
    local api_csrf_header=$controller_api_csrf_header
    local_api_request "$method" "$path"
}

require_controller_api_success() {
    local status=$1 label=$2 code
    case "$status" in 200|201|202|204) return 0 ;; esac
    code=$(jq -r '.code // .errorData.code // .err.code // .meta.msg // "unrecognized"' \
        "$controller_api_response" 2>/dev/null || printf unrecognized)
    die "$label failed with HTTP $status ($code)"
}

require_api_success() {
    local status=$1 label=$2 code
    case "$status" in 200|201|202|204) return 0 ;; esac
    code=$(jq -r '.code // .errorData.code // .err.code // "unrecognized"' "$api_response" 2>/dev/null || printf unrecognized)
    die "$label failed with HTTP $status ($code)"
}

validate_factory_public_state() {
    local system_json=$1
    jq -e '
        .deviceState == "notSetup" and
        .name == "UNVR" and
        (.hardware.firmwareVersion | type == "string" and length > 0) and
        ((.hardware.shortname // .hardware.shortName // .hardware.model) | type == "string" and test("^UNVR(4)?$")) and
        (.ustorage.disks | type) == "array" and
        ([.ustorage.disks[] | (.slot // .slotId // .slot_id)] | all(type == "number" and . >= 1 and . <= 4)) and
        ([.ustorage.disks[] | (.slot // .slotId // .slot_id)] | unique | length) ==
            ([.ustorage.disks[] | (.slot // .slotId // .slot_id)] | length)
    ' <<<"$system_json" >/dev/null \
        || die 'factory detector requires an unconfigured four-bay UNVR with a valid zero-to-four-bay storage inventory'
}

prompt_bootstrap_credentials() {
    if [[ -z "$ui_account" ]]; then
        prompt_value 'UI Account username or email: ' ui_account
        ui_account=$(printf '%s' "$ui_account" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -n "$ui_account" && ! "$ui_account" =~ [[:space:]] ]] \
            || die 'invalid UI Account username or email'
    fi
    if [[ -z "$ui_account_password" ]]; then
        prompt_secret 'UI Account password: ' ui_account_password
        [[ -n "$ui_account_password" ]] || die 'UI Account password cannot be empty'
    fi
    ssh_password=$TEMPORARY_SSH_PASSWORD
}

authenticate_ui_account() {
    local login_path=$1 status error_code mfa_cookie authenticator_type authenticator_id poll_deadline
    local sso_authenticated=false
    : > "$api_cookie"
    chmod 0600 "$api_cookie"
    rm -f -- "$api_csrf" "$api_headers" "$api_response"
    mfa_token=
    spinner_start 'Authenticating UI Account'
    status=$(
        printf '%s\0%s' "$ui_account_password" '' \
            | node -e '
                const fs = require("fs");
                const [password, token = ""] = fs.readFileSync(0).toString().split("\0");
                process.stdout.write(JSON.stringify({username: process.argv[1], password, token}));
              ' "$ui_account" \
            | local_api_request POST "$login_path"
    )
    spinner_stop 'Primary UI Account credentials checked'
    if [[ "$status" != 200 ]]; then
        error_code=$(jq -r '.code // empty' "$api_response" 2>/dev/null || true)
        if [[ "$error_code" == MFA_AUTH_REQUIRED ]]; then
            mfa_cookie=$(jq -er '.data.mfaCookie' "$api_response") \
                || die 'MFA response did not contain a session cookie'
            authenticator_id=$(jq -er '.data.user.default_mfa as $id | .data.authenticators[] | select(.id == $id) | .id' "$api_response") \
                || die 'default MFA authenticator is unavailable'
            authenticator_type=$(jq -er '.data.user.default_mfa as $id | .data.authenticators[] | select(.id == $id) | .type | ascii_upcase' "$api_response") \
                || die 'default MFA authenticator type is unavailable'
            case "$authenticator_type" in
                PUSH)
                    spinner_start 'Sending UniFi Verify push'
                    status=$(
                        printf '%s' "$mfa_cookie" \
                            | node -e '
                                const fs=require("fs");
                                process.stdout.write(JSON.stringify({method:"PUSH",mfaCookie:fs.readFileSync(0,"utf8")}));
                              ' \
                            | local_api_request POST /api/sso/login/mfa/send
                    )
                    require_api_success "$status" 'MFA push request'
                    spinner_stop 'UniFi Verify push sent'
                    mfa_cookie=$(jq -er '.mfaCookie // .data.mfaCookie' "$api_response") \
                        || die 'MFA push response did not contain a polling cookie'
                    spinner_start 'Approve the UniFi Verify push notification'
                    poll_deadline=$((SECONDS + 300))
                    while (( SECONDS < poll_deadline )); do
                        status=$(
                            printf '%s' "$mfa_cookie" \
                                | node -e '
                                    const fs=require("fs");
                                    process.stdout.write(JSON.stringify({mfaCookie:fs.readFileSync(0,"utf8")}));
                                  ' \
                                | local_api_request POST /api/sso/login/mfa/poll
                        )
                        case "$status" in
                            200) sso_authenticated=true; break ;;
                            202) sleep 2 ;;
                            403) die 'MFA push was denied' ;;
                            *) require_api_success "$status" 'MFA push polling' ;;
                        esac
                    done
                    [[ "$sso_authenticated" == true ]] || die 'MFA push approval timed out'
                    spinner_stop 'MFA approved'
                    ;;
                SMS|EMAIL)
                    spinner_start "Sending $authenticator_type verification code"
                    status=$(
                        printf '%s\0%s\0%s' "$authenticator_id" "$authenticator_type" "$mfa_cookie" \
                            | node -e '
                                const fs=require("fs");
                                const [id,method,mfaCookie]=fs.readFileSync(0).toString().split("\0");
                                process.stdout.write(JSON.stringify({id,method,mfaCookie}));
                              ' \
                            | local_api_request POST /api/sso/login/mfa/send
                    )
                    require_api_success "$status" "$authenticator_type MFA code request"
                    spinner_stop "$authenticator_type verification code sent"
                    ;;
                TOTP|BACKUP_CODE) ;;
                *) die "unsupported MFA authenticator type: $authenticator_type" ;;
            esac
            if [[ "$sso_authenticated" != true ]]; then
                prompt_secret 'UI Account MFA verification code: ' mfa_token
                [[ -n "$mfa_token" ]] || die 'MFA verification code cannot be empty'
                spinner_start 'Verifying UI Account MFA'
                status=$(
                    printf '%s\0%s' "$ui_account_password" "$mfa_token" \
                        | node -e '
                            const fs = require("fs");
                            const [password, token = ""] = fs.readFileSync(0).toString().split("\0");
                            process.stdout.write(JSON.stringify({username: process.argv[1], password, token}));
                          ' "$ui_account" \
                        | local_api_request POST "$login_path"
                )
                spinner_stop 'UI Account MFA verified'
            fi
        fi
    fi
    require_api_success "$status" 'UI Account authentication'
    jq -e '.email | type == "string"' "$api_response" >/dev/null \
        || die 'UI Account authentication returned an unexpected response'
}

authenticate_network_controller() {
    local unvr_ip=$controller_ip
    local api_cookie=$controller_api_cookie
    local api_response=$controller_api_response
    local api_headers=$controller_api_headers
    local api_csrf=$controller_api_csrf
    local api_csrf_header=$controller_api_csrf_header
    local mfa_token=
    authenticate_ui_account /api/auth/login
}

configure_ssh_and_updates() {
    local status
    spinner_start "Setting temporary SSH to \"$TEMPORARY_SSH_PASSWORD\" and disabling automatic updates"
    status=$(printf '%s' '{"ssh":{"agreementAccepted":true}}' | local_api_request PATCH /api/system)
    if [[ "$status" == 403 ]]; then
        spinner_clear
        authenticate_ui_account /api/auth/login
        spinner_start "Setting temporary SSH to \"$TEMPORARY_SSH_PASSWORD\" and disabling automatic updates"
        status=$(printf '%s' '{"ssh":{"agreementAccepted":true}}' | local_api_request PATCH /api/system)
    fi
    require_api_success "$status" 'SSH agreement acceptance'
    status=$(
        printf '%s' "$ssh_password" \
            | node -e 'const fs=require("fs"); process.stdout.write(JSON.stringify({password:fs.readFileSync(0,"utf8")}));' \
            | local_api_request POST /api/system/ssh/setpassword
    )
    require_api_success "$status" 'SSH password setup'
    status=$(printf '%s' '{"ssh":{"enabled":true}}' | local_api_request PATCH /api/system)
    require_api_success "$status" 'SSH enablement'
    status=$(printf '%s' '{"schedules":{"firmware":null},"useApplicationSchedules":true}' | local_api_request PATCH /api/system/updates/schedules)
    require_api_success "$status" 'automatic-update disablement'

    for _ in $(seq 1 120); do
        nc -z -G 2 "$unvr_ip" 22 >/dev/null 2>&1 && break
        sleep 2
    done
    nc -z -G 3 "$unvr_ip" 22 >/dev/null 2>&1 || die 'SSH did not become reachable after local setup'
    spinner_stop "Temporary SSH set to \"$TEMPORARY_SSH_PASSWORD\"; automatic updates disabled"
}

disable_update_ssh() {
    local status replacement random
    random=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | shasum -a 256 | awk '{print $1}')
    replacement="DisabledA1${random:0:48}"
    status=$(
        printf '%s' "$replacement" \
            | node -e 'const fs=require("fs"); process.stdout.write(JSON.stringify({password:fs.readFileSync(0,"utf8")}));' \
            | local_api_request POST /api/system/ssh/setpassword
    )
    replacement=
    random=
    case "$status" in 200|201|202|204) ;; *) return 1 ;; esac
    status=$(printf '%s' '{"ssh":{"enabled":false}}' | local_api_request PATCH /api/system)
    case "$status" in 200|201|202|204) ;; *) return 1 ;; esac
    temporary_update_ssh_configured=false
}

resume_setup_bootstrap() {
    local system_json
    system_json=$(public_system) || die 'configured UNVR API is unreachable'
    jq -e '
        ((.deviceState == "setup") or (.deviceState == "updateAvailable")) and
        .cloudConnected == true and
        .name == "UNVR" and
        ((.hardware.shortname // .hardware.shortName // .hardware.model) | type == "string" and test("^UNVR(4)?$"))
    ' <<<"$system_json" >/dev/null \
        || die 'SSH recovery requires the just-configured stock UNVR state'
    if [[ "$timeline_active" != true ]]; then
        print_target_summary
    fi
    timeline_step 1 9 'Resume temporary UNVR setup and enable secure SSH access'
    prompt_bootstrap_credentials
    authenticate_ui_account /api/auth/login
    configure_ssh_and_updates
}

factory_bootstrap() {
    local system_json status sso_user_file deadline timezone attempt setup_accepted=false
    system_json=$(public_system) || die 'factory UNVR setup API is unreachable'
    validate_factory_public_state "$system_json"
    if [[ "$timeline_active" != true ]]; then
        print_target_summary
    fi
    timeline_step 1 9 'Create temporary UNVR ownership and secure SSH access'
    prompt_bootstrap_credentials
    authenticate_ui_account /api/sso/login
    sso_user_file="$temp_root/sso-user.json"
    install -m 0600 "$api_response" "$sso_user_file"

    timezone=$(jq -r '.timezone // "UTC"' <<<"$system_json")
    for attempt in 1 2 3; do
        spinner_start "Creating temporary UNVR owner (attempt $attempt of 3)"
        status=$(
            printf '%s\0%s' "$ui_account_password" "$timezone" \
                | node -e '
                    const fs = require("fs");
                    const ssoUser = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
                    const [password, timezone] = fs.readFileSync(0).toString().split("\0");
                    process.stdout.write(JSON.stringify({
                      name: "UNVR",
                      password,
                      ssoUser,
                      timezone,
                      autoUpdates: {useApplicationSchedules: true, schedules: {firmware: null}},
                      updateFirmware: false,
                      sendDiagnostics: "anonymous",
                      isPrimary: true
                    }));
                  ' "$sso_user_file" \
                | local_api_request POST /api/setup
        )
        if [[ "$status" == 200 || "$status" == 201 || "$status" == 202 || "$status" == 204 ]]; then
            if [[ "$status" == 200 || "$status" == 201 ]]; then
                jq -e '.id | type == "string" and length > 0' "$api_response" >/dev/null \
                    || die 'factory setup did not return the temporary owner'
            fi
            setup_accepted=true
            spinner_stop 'Temporary UNVR owner created and console registered'
            break
        fi
        if [[ "$status" != 000 ]]; then
            require_api_success "$status" 'factory console setup'
        fi
        spinner_clear
        spinner_start 'Checking whether the interrupted setup request completed'
        deadline=$((SECONDS + 45))
        while (( SECONDS < deadline )); do
            system_json=$(public_system 2>/dev/null || true)
            if jq -e '((.deviceState == "setup") or (.deviceState == "updateAvailable")) and .cloudConnected == true' <<<"$system_json" >/dev/null 2>&1; then
                setup_accepted=true
                break
            fi
            sleep 3
        done
        if [[ "$setup_accepted" == true ]]; then
            spinner_stop 'Interrupted setup request completed successfully'
            break
        fi
        jq -e '.deviceState == "notSetup" and .cloudConnected == false' <<<"$system_json" >/dev/null 2>&1 \
            || die 'factory setup connection was interrupted in an ambiguous console state'
        spinner_stop 'Console remained unconfigured; retrying setup safely'
    done
    [[ "$setup_accepted" == true ]] || die 'factory console setup was not accepted after three attempts'

    deadline=$((SECONDS + 600))
    spinner_start 'Waiting for UniFi OS setup to finish'
    while (( SECONDS < deadline )); do
        system_json=$(public_system 2>/dev/null || true)
        if jq -e '((.deviceState == "setup") or (.deviceState == "updateAvailable")) and .cloudConnected == true' <<<"$system_json" >/dev/null 2>&1; then
            break
        fi
        sleep 3
    done
    jq -e '((.deviceState == "setup") or (.deviceState == "updateAvailable")) and .cloudConnected == true' <<<"$system_json" >/dev/null \
        || die 'factory console did not complete cloud setup within ten minutes'
    spinner_stop 'UniFi OS setup complete'

    configure_ssh_and_updates
}

start_master() {
    local fifo="$temp_root/askpass.fifo" helper="$temp_root/askpass.sh" writer ssh_rc
    nc -z -G 3 "$unvr_ip" 22 >/dev/null 2>&1 || die 'SSH port 22 is not reachable'
    rm -f -- "$fifo" || die 'could not clear the private SSH password channel'
    mkfifo -m 600 "$fifo" || die 'could not create the private SSH password channel'
    cat > "$helper" <<'EOF' || die 'could not create the SSH password helper'
#!/bin/bash
set -eu
IFS= read -r answer < "$UNVR_ASKPASS_FIFO"
printf '%s\n' "$answer"
EOF
    chmod 700 "$helper" || die 'could not secure the SSH password helper'
    (
        printf '%s\n' "$ssh_password" > "$fifo"
    ) &
    writer=$!
    askpass_writer_pid=$writer
    if DISPLAY=unvr-installer \
    SSH_ASKPASS="$helper" \
    SSH_ASKPASS_REQUIRE=force \
    UNVR_ASKPASS_FIFO="$fifo" \
    ssh \
        -M -S "$control_socket" -fNT \
        -o ControlPersist=3600 \
        -o ConnectTimeout=10 \
        -o ConnectionAttempts=1 \
        -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=6 \
        -o NumberOfPasswordPrompts=1 \
        -o PreferredAuthentications=keyboard-interactive,password \
        -o PubkeyAuthentication=no \
        -o StrictHostKeyChecking=accept-new \
        -o UserKnownHostsFile="$known_hosts" \
        -o LogLevel=ERROR \
        "root@$unvr_ip"; then
        ssh_rc=0
    else
        ssh_rc=$?
    fi
    if kill -0 "$writer" >/dev/null 2>&1; then
        kill "$writer" >/dev/null 2>&1 || true
    fi
    wait "$writer" >/dev/null 2>&1 || true
    askpass_writer_pid=
    rm -f -- "$fifo" "$helper" || die 'could not remove the SSH password helper'
    [[ "$ssh_rc" -eq 0 ]] || return "$ssh_rc"
    ssh -S "$control_socket" -O check "root@$unvr_ip" >/dev/null 2>&1 || die 'SSH ControlMaster did not start'
}

remote_phase() {
    local phase=$1
    shift
    ssh -S "$control_socket" -o BatchMode=yes "root@$unvr_ip" /bin/bash -s -- "$phase" "$@" < "$remote_engine"
}

phase_failure() {
    local label=$1 output_file=$2 detail
    spinner_clear
    detail=$(awk '/ERROR:|[Ee]rror:|[Ff]ailed/{line=$0} END{print line}' "$output_file" 2>/dev/null || true)
    [[ -n "$detail" ]] || detail=$(awk 'NF{line=$0} END{print line}' "$output_file" 2>/dev/null || true)
    detail=$(printf '%s' "$detail" | tr '\r\n' '  ' | sed 's/[[:space:]][[:space:]]*/ /g' | cut -c1-220)
    if [[ -n "$detail" ]]; then
        die "$label: $detail"
    fi
    die "$label"
}

quiet_remote_phase() {
    local label=$1 output_file="$temp_root/phase-output.log" rc
    shift
    : > "$output_file"
    spinner_start "$label"
    set +e
    remote_phase "$@" > "$output_file" 2>&1
    rc=$?
    set -e
    if [[ "$rc" -ne 0 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        quiet_remote_phase "$label" "$@"
        return
    fi
    [[ "$rc" -eq 0 ]] || phase_failure "$label failed" "$output_file"
    spinner_stop "$label"
}

quiet_local_step() {
    local label=$1 output_file="$temp_root/phase-output.log" rc
    shift
    : > "$output_file"
    spinner_start "$label"
    set +e
    "$@" > "$output_file" 2>&1
    rc=$?
    set -e
    if [[ "$rc" -ne 0 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        quiet_local_step "$label" "$@"
        return
    fi
    [[ "$rc" -eq 0 ]] || phase_failure "$label failed" "$output_file"
    spinner_stop "$label"
}

capture_remote_phase() {
    local label=$1 output_file="$temp_root/phase-output.log" rc
    shift
    : > "$output_file"
    captured_output=
    spinner_start "$label"
    set +e
    captured_output=$(remote_phase "$@" 2> "$output_file")
    rc=$?
    set -e
    if [[ "$rc" -ne 0 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        capture_remote_phase "$label" "$@"
        return
    fi
    [[ "$rc" -eq 0 ]] || phase_failure "$label failed" "$output_file"
    spinner_stop "$label"
}

capture_local_step() {
    local label=$1 output_file="$temp_root/phase-output.log" rc
    shift
    : > "$output_file"
    captured_output=
    spinner_start "$label"
    set +e
    captured_output=$("$@" 2> "$output_file")
    rc=$?
    set -e
    if [[ "$rc" -ne 0 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        capture_local_step "$label" "$@"
        return
    fi
    [[ "$rc" -eq 0 ]] || phase_failure "$label failed" "$output_file"
    spinner_stop "$label"
}

unas_setup_is_complete() {
    # Configured consoles redact isSetup from the unauthenticated response.
    # deviceState is the native setup-state signal, not SSH/cloud availability.
    jq -e '
        type == "object" and
        .hardware.shortname == "UNASPRO" and
        (.deviceState == "setup" or .deviceState == "updateAvailable") and
        ((has("isSetup") | not) or .isSetup == true)
    ' <<<"$1" >/dev/null 2>&1
}

show_unas_setup_checkpoint() {
    local notice=${1:-}
    spinner_clear
    if [[ -t 1 && ${TERM:-dumb} != dumb && "$timeline_dashboard_drawn" == true &&
          "$timeline_header_rewrite_safe" == true ]]; then
        printf '\r\033[%dA\033[J' "$((timeline_dashboard_rows + setup_checkpoint_rows))"
    fi
    timeline_dashboard_drawn=false
    printf '\n'
    print_box_border '┌' '┐'
    reset_box_heading 'Complete UNAS Pro setup'
    reset_box_line "Open https://$unvr_ip or use the UniFi mobile app."
    reset_box_line 'Finish console setup, then return here and press Enter.'
    reset_box_line 'You can leave storage-pool creation for later in UniFi Drive.'
    if [[ -n "$notice" ]]; then
        reset_box_line ''
        reset_box_colored_heading 33 "$notice"
    fi
    print_box_border '└' '┘'
    # Six box rows, plus the blank rows above it and above the dashboard.
    setup_checkpoint_rows=8
    [[ -z "$notice" ]] || setup_checkpoint_rows=10
    if [[ "$timeline_active" == true ]]; then
        timeline_header_rewrite_safe=true
        timeline_render_dashboard
    fi
}

hide_unas_setup_checkpoint() {
    if [[ -t 1 && ${TERM:-dumb} != dumb && "$setup_checkpoint_rows" -gt 0 &&
          "$timeline_dashboard_drawn" == true && "$timeline_header_rewrite_safe" == true ]]; then
        printf '\r\033[%dA\033[J' "$((timeline_dashboard_rows + setup_checkpoint_rows))"
        timeline_dashboard_drawn=false
        timeline_render_dashboard
    fi
    setup_checkpoint_rows=0
}

wait_for_user_unas_setup() {
    local setup_confirmation system notice=''
    while :; do
        show_unas_setup_checkpoint "$notice"
        prompt_value 'Press Enter to continue: ' setup_confirmation \
            || die 'input closed before UNAS setup could be verified'
        spinner_start 'Verifying completed UNAS setup'
        system=$(public_system 2>/dev/null || true)
        if unas_setup_is_complete "$system"; then
            spinner_stop 'Verified completed UNAS setup'
            hide_unas_setup_checkpoint
            return 0
        fi
        spinner_clear
        if jq -e 'type == "object" and .hardware.shortname == "UNASPRO"' \
            <<<"$system" >/dev/null 2>&1; then
            notice='Setup is not complete yet. Finish setup, then press Enter again.'
        else
            notice='Cannot verify the console. Check its connection, then try again.'
        fi
    done
}

completion_banner() {
    timeline_complete_current
    printf '\n\033[1;32m✓  CONVERSION COMPLETE! Your UNVR is now a UNAS Pro!\033[0m\n\n'
    print_box_border '┌' '┐'
    reset_box_line "UNAS setup verified at https://$unvr_ip"
    reset_box_line 'Manage your storage pools and shares in UniFi Drive.'
    print_box_border '└' '┘'
}

stage_file() {
    local source=$1 remote_name=$2 expected_hash=$3 actual source_size required_kib
    [[ "$remote_name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die 'invalid remote artifact name'
    [[ "$expected_hash" =~ ^[0-9a-f]{64}$ ]] || die "invalid expected artifact hash: $remote_name"
    [[ -f "$source" && ! -L "$source" ]] || die "local staged artifact is missing or unsafe: $remote_name"
    actual=$(sha "$source")
    [[ "$actual" == "$expected_hash" ]] || die "local staged artifact hash mismatch: $remote_name"
    source_size=$(stat -f '%z' "$source")
    [[ "$source_size" =~ ^[0-9]+$ ]] || die "local staged artifact size is invalid: $remote_name"
    required_kib=$((source_size / 1024 + 131072))
    ssh -S "$control_socket" -o BatchMode=yes "root@$unvr_ip" \
        "set -eu; install -d -m 700 /data/unvr-unas-installer; available=\$(df -Pk /data/unvr-unas-installer | awk 'NR == 2 {print \$4}'); test \"\$available\" -ge '$required_kib' || { echo 'ERROR: insufficient target space for staged artifact' >&2; exit 1; }; umask 077; final=/data/unvr-unas-installer/$remote_name; part=\"\$final.part.\$\$\"; trap 'rm -f -- \"\$part\"' EXIT HUP INT TERM; cat > \"\$part\"; test \"\$(sha256sum \"\$part\" | awk '{print \$1}')\" = '$expected_hash'; chmod 600 \"\$part\"; mv -f \"\$part\" \"\$final\"; trap - EXIT HUP INT TERM" \
        < "$source"
}

prepare_update_profiles() {
    local output_dir="$temp_root/update-profiles" output bundle expected_bundle expected_hash actual_hash args=()
    [[ -z "$unvr5_firmware" ]] || args+=(--unvr-5 "$unvr5_firmware")
    [[ -z "$unas5_firmware" ]] || args+=(--unas-5 "$unas5_firmware")
    if [[ -n "$unvr5_firmware" || -n "$unas5_firmware" ]]; then
        output=$("$profile_builder" "$output_dir" "${args[@]}")
    else
        output=$("$profile_builder" "$output_dir")
    fi
    bundle="$output_dir/unvr-unas-update-profiles.tar.gz"
    expected_bundle=$(printf '%s\n' "$output" | sed -n 's/^PROFILE_BUNDLE=//p')
    expected_hash=$(printf '%s\n' "$output" | sed -n 's/^PROFILE_BUNDLE_SHA256=//p')
    [[ -f "$bundle" && ! -L "$bundle" ]] || {
        printf 'ERROR: profile builder completed without its deterministic bundle\n' >&2
        return 1
    }
    [[ "$expected_bundle" == "$bundle" && "$expected_hash" =~ ^[0-9a-f]{64}$ ]] || {
        printf 'ERROR: profile builder output contract is incomplete\n' >&2
        return 1
    }
    actual_hash=$(sha "$bundle")
    [[ "$actual_hash" == "$expected_hash" ]] || {
        printf 'ERROR: profile builder output hash does not match its bundle\n' >&2
        return 1
    }
    printf '%s\n' "$output"
}

wait_for_reboot() {
    local deadline was_down=false
    spinner_start 'Waiting for UNVR to reboot and return over SSH'
    ssh -S "$control_socket" -O exit "root@$unvr_ip" >/dev/null 2>&1 || true
    rm -f -- "$control_socket"
    deadline=$((SECONDS + 180))
    while (( SECONDS < deadline )); do
        if ! nc -z -G 2 "$unvr_ip" 22 >/dev/null 2>&1; then was_down=true; break; fi
        sleep 2
    done
    [[ "$was_down" == true ]] || die 'UNVR did not go offline for reboot'
    deadline=$((SECONDS + 600))
    while (( SECONDS < deadline )); do
        if nc -z -G 2 "$unvr_ip" 22 >/dev/null 2>&1; then
            sleep 5
            if start_master >/dev/null 2>&1; then
                spinner_stop 'UNVR rebooted and SSH returned'
                return
            fi
        fi
        sleep 5
    done
    die 'UNVR SSH did not return within ten minutes'
}

prepare_original_controller_cleanup() {
    local association gateway controller_system status sites site endpoint matched=false
    local matching_site_count=0 matched_site= deadline authenticated_again=false
    capture_remote_phase 'Saved the original UniFi Network attachment' \
        factory-network-association "$unvr_ip"
    association=$captured_output
    controller_client_mac=$(printf '%s\n' "$association" | sed -n 's/^CLIENT_MAC=//p')
    gateway=$(printf '%s\n' "$association" | sed -n 's/^GATEWAY_IP=//p')
    [[ "$controller_client_mac" =~ ^[0-9a-f]{2}(:[0-9a-f]{2}){5}$ ]] \
        || die 'could not capture the exact UNVR client record for controller cleanup'
    validate_ipv4 "$gateway" || die 'could not capture the UNVR gateway for controller discovery'
    if [[ -z "$controller_ip" ]]; then
        controller_ip=$gateway
    fi
    validate_ipv4 "$controller_ip" || die 'the discovered UniFi Network controller address is invalid'
    [[ "$controller_ip" != "$unvr_ip" ]] || die 'the discovered Network controller resolves to the UNVR itself'

    controller_system=$(curl -ksS --connect-timeout 5 --max-time 20 \
        "https://$controller_ip/api/system" 2>/dev/null || true)
    jq -e '
        (.deviceState == "setup" or .deviceState == "updateAvailable") and
        ((.hardware.shortname // .hardware.shortName // .hardware.model) |
            type == "string" and length > 0 and test("^(UNVR|UNAS)"; "i") | not)
    ' <<<"$controller_system" >/dev/null 2>&1 \
        || die 'could not verify the original UniFi Network controller; rerun with --controller-ip if it is not the UNVR gateway'

    authenticate_network_controller
    spinner_start 'Locating the exact UNVR client record on its original Network site'
    sites=
    deadline=$((SECONDS + 300))
    while (( SECONDS < deadline )); do
        status=$(printf '' | controller_api_request GET /proxy/network/api/self/sites)
        case "$status" in
            200|201|202|204)
                sites=$(jq -r '
                    if (.data | type) == "array" then .data[]?
                    elif (.data.sites | type) == "array" then .data.sites[]?
                    elif type == "array" then .[]?
                    else empty
                    end | .name // .id // empty
                ' "$controller_api_response" 2>/dev/null || true)
                [[ -z "$sites" ]] || break
                ;;
            401|403)
                if [[ "$authenticated_again" == false ]]; then
                    spinner_clear
                    authenticate_network_controller
                    authenticated_again=true
                    spinner_start 'Waiting for the original Network application and site list'
                fi
                ;;
            000|502|503|504) ;;
            *) require_controller_api_success "$status" 'Network site discovery' ;;
        esac
        sleep 5
    done
    if [[ -z "$sites" ]]; then
        controller_cleanup_mode=unavailable
        spinner_stop 'Network sites remained unavailable; skipped optional stale-client cleanup'
        return
    fi
    while IFS= read -r site; do
        [[ "$site" =~ ^[A-Za-z0-9_-]+$ ]] || die 'the controller returned an unsafe Network site identifier'
        matched=false
        for endpoint in stat/sta rest/user; do
            status=$(printf '' | controller_api_request GET \
                "/proxy/network/api/s/$site/$endpoint/$controller_client_mac")
            if [[ "$status" == 200 ]] && jq -e --arg mac "$controller_client_mac" --arg ip "$unvr_ip" '
                .data | any(
                    (((.mac // "") | ascii_downcase) == $mac) and
                    ((.ip // "") == $ip)
                )
            ' "$controller_api_response" >/dev/null 2>&1; then
                matched=true
                break
            fi
        done
        if [[ "$matched" == true ]]; then
            matching_site_count=$((matching_site_count + 1))
            matched_site=$site
        fi
    done <<<"$sites"
    if [[ "$matching_site_count" -eq 0 ]]; then
        controller_cleanup_mode=not-present
        spinner_stop 'No stale UNVR client record was present on an accessible Network site'
        return
    fi
    [[ "$matching_site_count" -eq 1 ]] \
        || die 'the exact UNVR client record appeared on more than one Network site'
    controller_site=$matched_site
    controller_cleanup_mode=exact
    spinner_stop 'Saved the exact original Network site and client record'
}

unregister_prior_console_site() {
    quiet_remote_phase 'Unregistered the old UNVR console from Site Manager' factory-cloud-unregister
}

forget_prior_network_client() {
    local status payload verify_status attempt
    case "$controller_cleanup_mode" in
        unavailable|not-present)
            log 'Skipped optional Network client cleanup because no exact accessible stale record was available.'
            return
            ;;
        exact) ;;
        *) die 'the Network-controller cleanup state is unresolved' ;;
    esac
    [[ -n "$controller_ip" && -n "$controller_site" && -n "$controller_client_mac" ]] \
        || die 'the saved Network-controller cleanup boundary is incomplete'
    payload=$(jq -nc --arg mac "$controller_client_mac" '{cmd:"forget-sta",macs:[$mac]}')
    spinner_start 'Removing the stale offline UNVR record from the original Network controller'
    for attempt in 1 2 3; do
        status=$(printf '%s' "$payload" | controller_api_request POST \
            "/proxy/network/api/s/$controller_site/cmd/stamgr")
        if [[ "$status" == 401 || "$status" == 403 ]]; then
            spinner_clear
            authenticate_network_controller
            spinner_start 'Removing the stale offline UNVR record from the original Network controller'
            continue
        fi
        require_controller_api_success "$status" 'stale UNVR Network-client removal'
        jq -e '.meta.rc == "ok"' "$controller_api_response" >/dev/null 2>&1 \
            || die 'the Network controller did not accept the exact-client forget operation'
        sleep 2
        verify_status=$(printf '' | controller_api_request GET \
            "/proxy/network/api/s/$controller_site/rest/user/$controller_client_mac")
        if [[ "$verify_status" == 404 ]] || {
            [[ "$verify_status" == 200 ]] &&
            jq -e '(.data // []) | length == 0' "$controller_api_response" >/dev/null 2>&1
        }; then
            spinner_stop 'Removed the stale offline UNVR record from the original Network controller'
            return
        fi
    done
    die 'the stale UNVR client record remained on the original Network controller'
}

validate_controller_unas_identity() {
    local status endpoint deadline authenticated_again=false
    if [[ "$controller_cleanup_mode" != exact ]]; then
        log 'Skipped optional Network client enrichment; authoritative local UNAS Pro setup validation passed.'
        return
    fi
    spinner_start 'Waiting for the Network controller UNAS Pro record'
    deadline=$((SECONDS + 30))
    while (( SECONDS < deadline )); do
        for endpoint in stat/sta rest/user; do
            status=$(printf '' | controller_api_request GET \
                "/proxy/network/api/s/$controller_site/$endpoint/$controller_client_mac")
            if [[ "$status" == 401 || "$status" == 403 ]] && [[ "$authenticated_again" == false ]]; then
                spinner_clear
                authenticate_network_controller
                authenticated_again=true
                spinner_start 'Waiting for the Network controller UNAS Pro record'
                continue
            fi
            if [[ "$status" == 200 ]] && jq -e --arg mac "$controller_client_mac" --arg ip "$unvr_ip" '
                .data | any(
                    (((.mac // "") | ascii_downcase) == $mac) and
                    ((.ip // .last_ip // "") == $ip) and
                    ((.unifi_device_info_from_ucore // {}) as $ucore |
                        ((($ucore.product_line // "") | ascii_downcase) == "drive") and
                        (($ucore.product_model // "") == "UNAS Pro") and
                        (($ucore.product_shortname // "") == "UNASPRO") and
                        (($ucore.fw_version // "") == "5.1.33") and
                        (($ucore.ucore_device_status // "") == "online") and
                        ($ucore.managed == false)
                    )
                )
            ' "$controller_api_response" >/dev/null 2>&1; then
                spinner_stop 'Network controller recognized the unmanaged UNAS Pro'
                return
            fi
        done
        sleep 2
    done
    spinner_clear
    timeline_complete_current
    log 'Network client enrichment has not arrived yet; authoritative local UNAS Pro setup validation passed.'
}

wait_for_factory_reset() {
    local deadline was_down=false system_json
    spinner_start 'Waiting for the destructive factory reset to complete'
    if [[ -S "$control_socket" ]]; then
        ssh -S "$control_socket" -O exit "root@$unvr_ip" >/dev/null 2>&1 || true
    fi
    rm -f -- "$control_socket"
    deadline=$((SECONDS + 240))
    while (( SECONDS < deadline )); do
        if ! nc -z -G 2 "$unvr_ip" 22 >/dev/null 2>&1 &&
           ! nc -z -G 2 "$unvr_ip" 443 >/dev/null 2>&1; then
            was_down=true
            break
        fi
        sleep 2
    done
    [[ "$was_down" == true ]] || die 'UNVR did not go offline for the destructive factory reset'
    spinner_clear
    forget_prior_network_client
    spinner_start 'Waiting for the destructive factory reset to complete'
    deadline=$((SECONDS + 900))
    while (( SECONDS < deadline )); do
        system_json=$(public_system 2>/dev/null || true)
        if jq -e '
            .deviceState == "notSetup" and
            .cloudConnected == false and
            .name == "UNVR" and
            ((.hardware.shortname // .hardware.shortName // .hardware.model) | test("^UNVR(4)?$"))
        ' <<<"$system_json" >/dev/null 2>&1; then
            validate_factory_public_state "$system_json"
            : > "$api_cookie"
            : > "$known_hosts"
            chmod 0600 "$known_hosts"
            rm -f -- "$api_csrf" "$api_headers" "$api_response" "$api_csrf_header"
            mfa_token=
            spinner_stop 'Factory reset and external-storage erase completed'
            return
        fi
        sleep 5
    done
    die 'UNVR did not return to an unconfigured factory state within fifteen minutes'
}

confirm_destructive_reset() {
    local confirmation
    print_conversion_title
    print_destructive_reset_box
    while :; do
        prompt_value 'Continue with the destructive reset? [y/N] ' confirmation
        case "$confirmation" in
            y|Y|yes|YES|Yes)
                if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
                    printf '\033[H\033[2J\033[3J'
                    print_conversion_title
                fi
                return
                ;;
            ''|n|N|no|NO|No) log 'Destructive reset cancelled; no changes were made.'; exit 0 ;;
            *) printf 'Please answer yes or no.\n' ;;
        esac
    done
}

ensure_reset_ssh_access() {
    local system_json=$1 state master_ready=false master_rc=1
    state=$(jq -r '.deviceState // "unavailable"' <<<"$system_json" 2>/dev/null || printf unavailable)
    case "$state" in
        notSetup)
            if jq -e '
                .name == "UNVR" and
                ((.hardware.shortname // .hardware.shortName // .hardware.model) | test("^UNVR(4)?$"))
            ' <<<"$system_json" >/dev/null 2>&1; then
                factory_bootstrap
            elif jq -e '
                .name == "UNAS Pro" and
                ((.hardware.shortname // .hardware.shortName // .hardware.model) == "UNASPRO")
            ' <<<"$system_json" >/dev/null 2>&1; then
                if [[ "$timeline_active" != true ]]; then
                    print_target_summary
                fi
                timeline_step 1 9 'Connect to the existing logical UNAS retry state'
                prompt_bootstrap_credentials
                nc -z -G 3 "$unvr_ip" 22 >/dev/null 2>&1 \
                    || die 'logical UNAS retry requires the temporary SSH access left by this installer; factory-reset this older conversion first'
            else
                die 'unconfigured console identity is neither a stock UNVR nor this installer logical UNAS retry state'
            fi
            ;;
        setup|updateAvailable)
            if [[ "$timeline_active" != true ]]; then
                print_target_summary
            fi
            timeline_step 1 9 'Connect to the existing temporary UNVR owner'
            prompt_bootstrap_credentials
            if nc -z -G 3 "$unvr_ip" 22 >/dev/null 2>&1; then
                spinner_start 'Checking existing temporary SSH access'
                if start_master >/dev/null 2>&1; then
                    master_rc=0
                else
                    master_rc=$?
                fi
                spinner_stop
            fi
            if [[ "$master_rc" -eq 0 ]]; then
                master_ready=true
                spinner_start "Reusing temporary SSH password \"$TEMPORARY_SSH_PASSWORD\""
                spinner_stop
            else
                rm -f -- "$control_socket"
                authenticate_ui_account /api/auth/login
                configure_ssh_and_updates
            fi
            ;;
        *) die 'console must be locally reachable and either configured or at the factory setup screen before reset' ;;
    esac
    if [[ "$master_ready" == false ]]; then
        spinner_start 'Establishing the reset SSH session'
        start_master
        spinner_stop 'Reset SSH session established'
    else
        spinner_start 'Using the existing reset SSH session'
        spinner_stop 'Reset SSH session established'
    fi
}

run_destructive_factory_reset() {
    local system_json=$1 reset_output reset_rc
    confirm_destructive_reset
    ensure_reset_ssh_access "$system_json"
    capture_remote_phase 'Validated the physical UNVR and destructive reset boundary' factory-reset-preflight
    prepare_original_controller_cleanup
    unregister_prior_console_site
    spinner_start 'Erasing all installed drive data and factory-resetting the UNVR'
    set +e
    reset_output=$(remote_phase factory-reset-wipe 2>&1)
    reset_rc=$?
    set -e
    spinner_clear
    if [[ "$reset_rc" -ne 0 && "$reset_rc" -ne 255 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        reset_rc=255
    fi
    [[ "$reset_rc" -eq 0 || "$reset_rc" -eq 255 ]] \
        || die "stock Ubiquiti destructive reset failed: $reset_output"
    wait_for_factory_reset
}

run_install_5x() {
    timeline_step 2 9 'Verify signed UNVR 5.1.33 baseline and storage-preservation state'
    quiet_remote_phase 'Validated firmware, hardware and resume state' preflight-5x
    if [[ "$dry_run" == true ]]; then
        quiet_remote_phase 'Validated the storage-preservation gate without changes' disk-preflight-clean-5x
        log 'dry-run complete: no target or local persistent state was changed'
        return
    fi

    local profile_output profile_bundle profile_hash disk_info factory_pool_token
    local factory_pool_needs_erase=false recreated_pool_needs_erase=false
    local reboot_rc reboot_output
    timeline_step 3 9 'Build the hash-verified official UNAS compatibility payload'
    capture_local_step 'Built and verified the official compatibility payload' prepare_update_profiles
    profile_output=$captured_output
    profile_bundle=$(printf '%s\n' "$profile_output" | sed -n 's/^PROFILE_BUNDLE=//p')
    profile_hash=$(printf '%s\n' "$profile_output" | sed -n 's/^PROFILE_BUNDLE_SHA256=//p')
    [[ -f "$profile_bundle" && "$profile_hash" =~ ^[0-9a-f]{64}$ ]] \
        || die 'profile builder did not return a valid bundle'

    capture_remote_phase 'Classified and locked the storage state safely' lock-clean-disk-5x
    disk_info=$captured_output
    printf '%s\n' "$disk_info" | grep -q '^DISK_TOKEN=' \
        || die 'the zero-to-four-drive topology could not be locked safely'
    factory_pool_token=$(printf '%s\n' "$disk_info" | sed -n 's/^DISK_TOKEN=//p')
    if printf '%s\n' "$disk_info" | grep -qx 'FACTORY_POOL_NEEDS_ERASE=1'; then
        factory_pool_needs_erase=true
    fi
    if printf '%s\n' "$disk_info" | grep -qx 'RECREATED_POOL_NEEDS_ERASE=1'; then
        recreated_pool_needs_erase=true
    fi
    timeline_step 4 9 'Capture rollback state and install safety guards'
    quiet_remote_phase 'Verified the rollback backup' backup-5x
    quiet_remote_phase 'Applied the update safety guard' update-guard
    quiet_remote_phase 'Applied the dedicated-NAS service guard' dedicated-guard
    timeline_step 5 9 'Build exact native Btrfs, Zstd and FUSE modules'
    quiet_local_step 'Uploaded the immutable build and compatibility payload' stage_file "$profile_bundle" update-profiles.tar.gz "$profile_hash"
    quiet_remote_phase 'Verified native Btrfs, Zstd and FUSE modules' modules "$profile_hash"
    if [[ "$factory_pool_needs_erase" == true ]]; then
        quiet_remote_phase 'Returned slot 1 to a blank onboarding state' erase-factory-pool-5x "$factory_pool_token"
        capture_remote_phase 'Revalidated blank slot-1 storage' disk-preflight-clean-5x
        disk_info=$captured_output
        printf '%s\n' "$disk_info" | grep -qx 'DISK_STATE=blank' \
            || die 'slot 1 did not remain blank after factory-pool cleanup'
    elif [[ "$recreated_pool_needs_erase" == true ]]; then
        quiet_remote_phase 'Removed the interrupted empty storage pool' erase-recreated-pool-5x "$factory_pool_token"
        capture_remote_phase 'Revalidated blank slot-1 storage' disk-preflight-clean-5x
        disk_info=$captured_output
        printf '%s\n' "$disk_info" | grep -qx 'DISK_STATE=blank' \
            || die 'slot 1 did not remain blank after interrupted-pool cleanup'
    fi
    timeline_step 6 9 'Install scoped UNAS Pro identity and official Drive userspace'
    quiet_remote_phase 'Installed and verified the scoped UNAS Pro identity' direct-5x-profile "$profile_hash"
    quiet_remote_phase 'Installed and verified official UniFi Drive 4.3.10' direct-5x-packages
    timeline_step 7 9 'Verify UNAS services while preserving installed storage'
    quiet_remote_phase 'Verified the UNAS pre-storage state' prestorage-5x

    timeline_step 8 9 'Reboot and run pre-storage health validation'
    set +e
    reboot_output=$(remote_phase reboot)
    reboot_rc=$?
    set -e
    if [[ "$reboot_rc" -ne 0 && "$reboot_rc" -ne 255 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        reboot_rc=255
    fi
    [[ "$reboot_rc" -eq 0 || "$reboot_rc" -eq 255 ]] || die 'unexpected failure while requesting reboot'
    if ! printf '%s\n' "$reboot_output" | grep -qx 'REBOOT_ALREADY_COMPLETE=1'; then
        wait_for_reboot
    else
        spinner_start 'Using the completed post-install reboot'
        spinner_stop 'Completed post-install reboot detected'
    fi
    quiet_remote_phase 'Validated UNAS services and preserved storage after reboot' validate-prestorage-5x
    timeline_step 9 9 'Complete official UNAS setup and verify the handoff'
    quiet_remote_phase 'Prepared the official UNAS Pro setup flow' logical-unadopt
    set +e
    reboot_output=$(remote_phase handoff-reboot)
    reboot_rc=$?
    set -e
    if [[ "$reboot_rc" -ne 0 && "$reboot_rc" -ne 255 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        reboot_rc=255
    fi
    [[ "$reboot_rc" -eq 0 || "$reboot_rc" -eq 255 ]] || die 'unexpected failure while requesting the UNAS handoff reboot'
    if ! printf '%s\n' "$reboot_output" | grep -qx 'HANDOFF_REBOOT_ALREADY_COMPLETE=1'; then
        wait_for_reboot
    fi
    quiet_remote_phase 'Validated unmanaged UNAS Pro discovery and local setup' validate-unadopted-handoff-5x
    validate_controller_unas_identity
    wait_for_user_unas_setup
    completion_banner
}

run_normalize_to_5x() {
    local normalize_rc normalize_output
    timeline_step 2 9 'Verify signed UNVR 5.1.33 baseline and storage-preservation state'
    quiet_remote_phase 'Validated the source firmware for normalization' normalization-preflight
    if [[ "$dry_run" == true ]]; then
        log 'dry-run: source is eligible for stock signed normalization to 5.1.33'
        log 'dry-run complete: no firmware was downloaded, staged or written'
        return
    fi
    quiet_remote_phase 'Downloaded signed UNVR 5.1.33 directly to the console' normalization-image-stage
    quiet_remote_phase 'Verified firmware with the stock Ubiquiti updater' normalization-image-check
    spinner_start 'Applying signed UNVR 5.1.33 through the stock updater'
    set +e
    normalize_output=$(remote_phase normalize-to-5x 2>&1)
    normalize_rc=$?
    set -e
    spinner_clear
    if [[ "$normalize_rc" -ne 0 && "$normalize_rc" -ne 255 && "$interrupt_declined" == true ]]; then
        interrupt_declined=false
        normalize_rc=255
    fi
    [[ "$normalize_rc" -eq 0 || "$normalize_rc" -eq 255 ]] \
        || die "stock firmware normalization failed: $normalize_output"
    wait_for_reboot
    quiet_remote_phase 'Validated exact 5.1.33 after normalization' preflight-5x
    run_install_5x
}

run_install() {
    local baseline
    baseline=$(remote_phase detect-baseline)
    case "$baseline" in
        BASELINE=5.1.33) run_install_5x ;;
        BASELINE=normalization-required) run_normalize_to_5x ;;
        *) die "unsupported UNVR baseline: $baseline" ;;
    esac
}

run_status() {
    remote_phase status
}

run_rollback() {
    local confirmation
    printf 'Rollback restores software/configuration but preserves the SATA pool and all data.\n'
    prompt_value 'Type exactly "ROLL BACK UNVR SOFTWARE": ' confirmation
    [[ "$confirmation" == 'ROLL BACK UNVR SOFTWARE' ]] || die 'rollback was not confirmed'
    remote_phase rollback
}

run_unadopt() {
    local confirmation
    printf 'This unregisters the console from UniFi cloud and clears its ULP owner so it can be adopted again as UNASPRO.\n'
    printf 'The SATA storage pool is not formatted or modified. A guarded local backup is created first.\n'
    prompt_value 'Type exactly "UNREGISTER AND READOPT AS UNAS": ' confirmation
    [[ "$confirmation" == 'UNREGISTER AND READOPT AS UNAS' ]] || die 'logical UNAS unadoption was not confirmed'
    remote_phase logical-unadopt
    log 'Site Manager should offer a transient Setup and Merge prompt while this Mac is on the same LAN.'
    log 'The unregistered console will not become a persistent Site Manager card until setup registers it to the owner account.'
    log 'If the prompt is dismissed, use a fresh Site Manager session or complete setup at the local URL; the resulting UNAS console can then be merged.'
    log "UNASPRO adoption is ready at https://$unvr_ip"
}

parse_args "$@"
temp_root=$(mktemp -d /private/tmp/unvr-unas-installer.XXXXXX)
materialize_embedded_helpers
check_macos
control_socket="$temp_root/ssh.sock"
known_hosts="$temp_root/known_hosts"
api_cookie="$temp_root/api-cookies"
api_response="$temp_root/api-response.json"
api_headers="$temp_root/api-response.headers"
api_csrf="$temp_root/api-csrf-token"
api_csrf_header="$temp_root/api-csrf-header"
controller_api_cookie="$temp_root/controller-api-cookies"
controller_api_response="$temp_root/controller-api-response.json"
controller_api_headers="$temp_root/controller-api-response.headers"
controller_api_csrf="$temp_root/controller-api-csrf-token"
controller_api_csrf_header="$temp_root/controller-api-csrf-header"
prompt_ip
if [[ "$command" == install && "$dry_run" == false ]]; then
    initial_system=$(public_system 2>/dev/null || true)
    jq -e '.deviceState == "notSetup" or .deviceState == "setup" or .deviceState == "updateAvailable"' \
        <<<"$initial_system" >/dev/null 2>&1 \
        || die 'UNVR local API is unavailable or returned an unsupported state before destructive reset'
    run_destructive_factory_reset "$initial_system"
fi
if [[ "$command" == install || "$command" == setup-only ]]; then
    initial_system=$(public_system 2>/dev/null || true)
    initial_state=$(jq -r '.deviceState // "unavailable"' <<<"$initial_system" 2>/dev/null || printf unavailable)
    if [[ "$initial_state" == notSetup ]]; then
        if [[ "$dry_run" == true ]]; then
            validate_factory_public_state "$initial_system"
            log 'dry-run: factory UNVR and zero-to-four-drive inventory detected; ownership and SSH were not configured'
            exit 0
        fi
        factory_bootstrap
    elif [[ "$initial_state" == setup || "$initial_state" == updateAvailable ]] && ! nc -z -G 3 "$unvr_ip" 22 >/dev/null 2>&1; then
        if [[ "$dry_run" == true ]]; then
            log 'dry-run: configured stock UNVR detected with SSH disabled; no session or setting was changed'
            exit 0
        fi
        resume_setup_bootstrap
    else
        [[ "$command" != setup-only ]] || die 'setup-only requires a factory or just-configured console with SSH still disabled'
        if [[ "$timeline_active" != true ]]; then
            print_target_summary
        fi
        timeline_step 1 9 'Connect to the existing temporary UNVR owner'
        prompt_ssh_password
    fi
else
    prompt_ssh_password
fi
if [[ "$command" == setup-only ]]; then
    timeline_complete_current
    log 'setup-only complete; firmware and conversion state were not changed'
    exit 0
fi
if [[ "$command" == install ]]; then
    spinner_start 'Establishing secure SSH session'
fi
start_master
if [[ "$command" == install ]]; then
    spinner_stop 'Secure SSH session established'
fi

case "$command" in
    install) run_install ;;
    status) run_status ;;
    disarm) remote_phase disarm-update ;;
    rollback) run_rollback ;;
    unadopt) run_unadopt ;;
esac
