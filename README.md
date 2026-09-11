# UniFi UNVR to UNAS Pro Conversion

Follow [@taimurayaz](https://x.com/taimurayaz) on X for follow-up testing and future UniFi projects.

<video controls playsinline muted width="100%" src="https://github.com/user-attachments/assets/763a2fb8-9b94-4ca8-af0a-272e7cc48d6b"></video>

> [!CAUTION]
> This is an unofficial community project and is not affiliated with, endorsed
> by, or supported by Ubiquiti. It will probably void any applicable warranty,
> and the normal conversion permanently erases the UNVR configuration and every
> installed SATA drive. Extensive safeguards have been built in to protect the
> bootloader and recovery environment, verify every artifact, reject unknown
> states, and reduce the chance of an unusable device. However, the possibility
> of a device brick cannot be eliminated. Proceed entirely at your own risk. The
> software is provided “as is,” and the author is not liable for data loss,
> hardware damage, loss of service, warranty loss, or other damages.

This project turns a physical four-bay UniFi Network Video Recorder into a
logical UNAS Pro running UniFi Drive. The self-contained macOS installer,
[`convert.sh`](convert.sh), handles the reset, software installation, validation,
reboots, and handoff to the familiar UniFi setup experience.

This independent project explores interoperability and repurposing of user-owned
Ubiquiti hardware for educational and research purposes. The MIT licence covers
original project code; third-party software remains governed by its respective
licences.

> [!NOTE]
> The conversion, console setup, and manual Drive update have been verified on
> a four-bay UNVR. Tested software versions are listed below.

## Tested compatibility

| Component | Tested version or target |
| --- | --- |
| Mac host | macOS 26.0.1 |
| Hardware | Four-bay UNVR |
| Previously exercised source UNVR releases | UniFi OS 4.1.22, 5.1.30, 5.1.31, and 5.1.33 |
| Pinned conversion baseline | Signed UNVR 5.1.33 |
| Logical conversion target | UNAS Pro 5.1.33 |
| OS updates after conversion | Not supported by this fixed-release converter |
| UniFi Drive | 4.3.10 initial install; manual Control Plane update to 4.4.9 verified on OS 5.1.33 |

The following combinations were tested on the development UNVR:

| Physical UNVR base | Logical UniFi OS identity | UniFi Drive | Validation completed |
| --- | --- | --- | --- |
| 4.1.22 | UNAS Pro 4.1.22 | 1.19.1 | Drive UI and registration, storage, personal and shared drives, SMB, NFS, snapshots, reboot persistence, and recovery persistence |
| 5.1.31 | UNAS Pro 4.3.10 | 3.1.8 | Database migration 74, storage API, four-bay mapping, SMB, NFS, WSDD, discovery, and reboot persistence |
| 5.1.31 | UNAS Pro 5.1.32 | 4.3.10 | Previous installer target, official setup and adoption, storage creation, SMB, checksum verification, and reboot persistence |
| 5.1.31 | UNAS Pro 5.1.32 | 4.4.9 | Manual Control Plane update from 4.3.10, official binary hash, database migration 129, storage API, SMB, guarded profile validation, and reboot persistence |
| 5.1.33 | UNAS Pro 5.1.33 | 4.3.10 | Fresh direct conversion, native modules, handoff reboot, official console setup, disabled auto-updates, and temporary SSH rotation/disablement |
| 5.1.33 | UNAS Pro 5.1.33 | 4.4.9 | Manual Control Plane update from 4.3.10, official binary hash, migration 129 complete, Drive API, fixed-release guard validation, and auto-updates remaining off |

The direct 5.1.33 conversion and subsequent Control Plane update to Drive 4.4.9
were verified on September 11, 2026.

Earlier development testing of 5.1.33 with Drive 4.3.10, using the now-retired
guarded OS-update path, also covered storage, SMB, and reboot persistence.

Official Drive 1.16.11 from UNAS Pro 4.1.22 also passed the isolated backend
smoke-test phase. That test deliberately excluded normal package installation,
storage mutation, SMB, NFS, and persistent integration, so it is recorded as a
smoke-tested predecessor rather than a complete supported runtime stage.

Updating UniFi Drive from 4.3.10 to 4.4.9 through Control Plane has now been
verified on both the previous 5.1.31 physical baseline and the current 5.1.33
baseline. This confirms that exact application-update path only. Compatibility
with future Drive releases is not guaranteed.

The converter automatically normalizes an eligible stock UNVR to the exact
signed 5.1.33 baseline. Depending on the installed release, this can be an
upgrade or a downgrade. The image is downloaded from Ubiquiti, checked against
its pinned size and SHA-256, validated by the stock firmware verifier, and
installed with the stock updater before conversion continues.

This does not mean every UNVR release is automatically supported. A source must
pass the hardware, architecture, kernel, bootloader, storage, and stock-updater
checks built into the converter. An unknown or incompatible source is rejected
without attempting normalization.

## Requirements

You need:

- a physical four-bay **UNVR**;
- a Mac running macOS;
- the UNVR's local IPv4 address;
- your UI Account username or email, password, and MFA method;
- a trusted local network connecting the Mac, UNVR, and original UniFi
  controller;
- stable power and internet access; and
- a backup of anything you want to keep.

The converter accepts zero to four installed SATA drives. Every installed SATA
drive will be erased after you approve the conversion.

This release is not intended for UNVR Pro, CloudKey, Dream Machine, third-party
ARM servers, or arbitrary Debian systems.

## Install the macOS prerequisites

Open **Terminal** on your Mac. You can find it with Spotlight by pressing
<kbd>Command</kbd> + <kbd>Space</kbd>, typing `Terminal`, and pressing
<kbd>Return</kbd>.

Install Apple's Command Line Tools:

```bash
xcode-select --install
```

The converter also needs Homebrew packages for JSON processing, firmware
extraction, Node.js, and Python. If you do not have Homebrew, install it from
[brew.sh](https://brew.sh/). Then run:

```bash
brew install jq squashfs node python xz
```

Confirm the required tools are available:

```bash
command -v jq unsquashfs node python3 ar xz
```

Each command should print a path. The converter performs its own complete tool
check and stops before conversion if something is missing.

## Download the converter

In Terminal, run:

```bash
git clone https://github.com/TaimurAyaz/unifi-unvr-to-unas.git
cd unifi-unvr-to-unas
chmod +x convert.sh
```

That is the complete installation. You do not need to find firmware, download
Debian packages, or copy helper scripts. `convert.sh` includes its helper tooling
and downloads only pinned artifacts whose sizes and SHA-256 hashes match its
built-in manifests.

The build payload includes all 165 packages for the on-device compiler
environment, including the Debian archive keyring, plus the signed Debian
snapshot index. The UNVR bootstraps that environment from a verified local
mirror with network access disabled, then compiles the native modules itself.

## Before you run: further reading

The installer presents a concise summary and asks for confirmation before it
erases anything. The sections below explain the same behavior in more detail
for anyone who wants to understand exactly what the conversion does.

<details>
<summary><strong>What will be erased, preserved, and left unchanged</strong></summary>

### What will be erased

- The UNVR console configuration
- All data on every installed SATA drive
- Protect recordings and application data
- RAID metadata, partitions, storage pools, shares, backups, and files

The erase applies to every detected SATA drive, not only the first drive.

### What will be preserved

- The original UniFi Network site
- Other consoles, network devices, and clients
- The UNVR's internal recovery path

### What will not be modified

- The recovery kernel and recovery environment
- EEPROM or other physical hardware identity

Official firmware files are hash-verified and never patched. If necessary, the
installed UNVR operating system is replaced through Ubiquiti's stock updater
with the exact supported, signed UNVR 5.1.33 release.

Factory reset retains the installed physical firmware. A reset after this
conversion therefore leaves stock UNVR 5.1.33. When the exact baseline is
already installed, normalization is skipped. Other eligible stock releases
are normalized with Ubiquiti's signed updater, which can replace UNVR U-Boot
and reset its redundant environment. Unknown bootloader hashes remain blocked
before reset or normalization.

### Console cleanup

The installer unregisters this UNVR console from Site Manager and, when the
original UniFi Network site is accessible, forgets only this UNVR's exact stale
client record. If the Network application is updating, the converter waits up
to five minutes for its site list to return. If no exact accessible record is
available after that window, this optional cosmetic cleanup is skipped. The
Network site and every other controller device and client are preserved.

Ubiquiti may retain an empty Site Manager site shell. It can be reused when the
converted UNAS is set up.

</details>

<details>
<summary><strong>How your UI Account credentials are used</strong></summary>

The installer requests your UI Account username or email, password, and MFA
verification when required. They automate the normal UniFi ownership, local
setup, controller cleanup, and final handoff operations.

| Credential or session | Purpose | Where it exists |
| --- | --- | --- |
| UI Account username and password | Authenticates the local UNVR, creates temporary ownership, authenticates the original Network controller, and unregisters temporary ownership | Foreground input process, in-kernel pipe buffer, and running Bash process |
| MFA code or approval | Completes Ubiquiti authentication | Process memory and an in-kernel pipe buffer |
| Local cookies and CSRF tokens | Maintains local console and controller sessions | Permission-restricted files in a private `/private/tmp/unvr-unas-installer.*` directory |
| Temporary SSH password | Enables automated on-device work | The fixed public value `UnvrToUnasConversion1` |

The password and MFA code are entered interactively and hidden. They are never
placed in command arguments and are not intentionally written to logs, the
repository, the compatibility payload, or ordinary files. The animated input
reader returns each value through a permission-restricted named pipe. The pipe
has a filesystem name, but credential bytes stay in the kernel pipe buffer. It
is removed immediately after each prompt.

MFA can be requested more than once because the factory reset destroys the
first console session and the original Network controller may require a
separate authenticated session.

Session cookies and CSRF files are deleted by the normal cleanup handler. A Mac
power failure, `kill -9`, or operating-system crash can prevent cleanup, leaving
the permission-restricted temporary directory until macOS removes it.

### Network destinations

The script communicates with:

- `https://<UNVR-IP>` for local setup, reset, SSH control, and conversion;
- `https://<controller-IP>` to remove the exact stale UNVR client record;
- `fw-download.ubnt.com` for pinned official Ubiquiti firmware and packages; and
- `snapshot.debian.org` for the pinned Debian dependency closure.

The local UniFi services communicate with Ubiquiti's UI identity services as
part of normal UI Account authentication. This project has no author telemetry
endpoint and does not send credentials to GitHub or to the author. Temporary
UniFi setup selects the platform's anonymous diagnostics option. Any resulting
diagnostics are controlled by UniFi software.

Factory UniFi consoles commonly use self-signed or locally issued TLS
certificates. Local API traffic is encrypted with HTTPS, but the converter
disables public-CA certificate verification for local IP connections. It cannot
cryptographically prove that the responding local IP is your console. Verify
the address and run the converter only on a trusted private network.

### Temporary SSH access

You do not need to enable SSH or know an existing SSH password. The installer
temporarily enables SSH and assigns the known password
`UnvrToUnasConversion1`. The on-device finalizer rotates the password and
disables SSH after official UNAS setup.

Because the temporary password is public, keep the UNVR on a trusted LAN. If
conversion is interrupted, SSH may remain enabled until the installer resumes
or you disable it from the local Control Plane.

</details>

<details>
<summary><strong>How the software conversion works</strong></summary>

This is a software conversion, not a physical hardware or EEPROM conversion.
The device keeps its UNVR recovery environment, physical identity, port layout,
and four-bay hardware topology. Firmware normalization can change the UNVR
bootloader through Ubiquiti's stock signed updater.

The workflow:

1. establishes temporary ownership and guarded SSH access;
2. erases the console and all installed SATA storage;
3. normalizes eligible stock UNVR firmware to signed UNVR 5.1.33;
4. downloads and hash-verifies the immutable compatibility payload;
5. captures rollback state and applies update and service guards;
6. builds native Btrfs, Zstd, and FUSE modules on the UNVR;
7. installs the scoped UNAS Pro identity and official UniFi Drive userspace;
8. reboots and validates services, storage state, and discovery; and
9. removes temporary ownership, waits for you to finish official UNAS Pro setup,
   and verifies the console's setup status before reporting completion.

Automatic updates are disabled during conversion. Future releases can change
kernels, services, dependencies, or hardware checks, so an update offered by a
dashboard is not proof of compatibility.

</details>

## Run the conversion

> [!IMPORTANT]
> Run the executable directly as `./convert.sh`. Do not run `sh convert.sh`.
> The latter forces the script through a POSIX shell, ignores the required Bash
> interpreter in the script header, and produces a syntax error before the
> converter can contact or modify the UNVR.

Run without arguments and enter the UNVR's IPv4 address when prompted:

```bash
./convert.sh
```

Or provide the address directly:

```bash
./convert.sh --ip 192.168.1.192
```

Do not use `sudo`, and never place your UI Account password or MFA code in the
command.

The converter displays its disclosure and asks:

```text
Continue with the destructive reset? [y/N]
```

Answer `y` or `yes` only when you are ready to permanently erase the console
configuration and every installed SATA drive. Answering `n`, `no`, or pressing
<kbd>Return</kbd> exits without starting the reset.

During conversion:

1. Enter your UI Account information and MFA response when prompted.
2. Leave Terminal open.
3. Keep the Mac and UNVR powered on.
4. Do not remove or insert SATA drives.
5. Allow every reboot to finish, even when the web interface temporarily goes
   offline.

Several reboots and large downloads are normal. The live dashboard shows the
current action, overall progress, and estimated time remaining.

## Complete UNAS setup

Near the end, the script shows the local setup URL and pauses:

```text
Press Enter to continue:
```

Open the printed URL or use the UniFi mobile app to finish console setup.
Return to Terminal and press Enter. The script checks the console's local API;
pressing Enter alone does not confirm setup. If setup is incomplete or the
console cannot be reached, it asks you to finish setup or check the connection
and press Enter again. This check does not require SSH to remain enabled.

Once setup is verified, the script displays the conversion-complete message.
Temporary-access cleanup is handled by the on-device finalizer, separately
from this console-setup check.

Choose and create your storage pool in UniFi Drive when you are ready. The
converter does not create a pool or select disks and RAID settings for you.
You can finish console setup without creating storage. After creating a pool,
create shares and access credentials through UniFi Drive.

Before relying on the system, copy a test file, verify its checksum, reboot the
console, reconnect, and verify the checksum again. Important data should always
have an independent backup.

## OS updates

This is a fixed-release converter targeting **UNAS Pro 5.1.33**. Automatic OS
and application updates are disabled. Control Plane OS firmware installations
are blocked, even if a newer version appears in the interface.

There is no separate update-preparation step. The old `prepare-os-update` and
arming commands are disabled. Future OS-update support will be considered
separately; do not bypass the firmware guard.

Manual Drive application updates use the existing version-specific
compatibility checks. They are separate from OS updates, and future Drive
versions are not guaranteed to work.

## Dry run

To check the target and storage inventory without resetting, downloading,
installing, formatting, rebooting, or persisting changes:

```bash
./convert.sh install --ip 192.168.1.192 --dry-run
```

A dry run cannot prove that the complete conversion will succeed.

## If the installer is interrupted

Pressing `Ctrl+C` asks whether you really want to stop. Answering `yes` exits and
runs local cleanup. Answering `no` redraws the dashboard and retries or reopens
the interrupted guarded action.

An on-device factory reset or reboot that has already started cannot be stopped
by closing Terminal. Wait for the console to return before rerunning the
converter.

Running the normal `install` command again presents the destructive-reset
disclosure again and, if approved, erases every installed SATA drive again.

Do not manually install packages, flash UNAS firmware, rewrite EEPROM values,
or modify the bootloader to bypass a safety check. When reporting a problem,
include the exact error and stage number, but never include passwords, MFA
codes, cookies, tokens, serial numbers, or other private identifiers.

## Frequently asked questions

### Do I need to enable SSH first?

No. The installer configures temporary SSH itself.

### Can I run it without a drive?

Yes. Zero to four drives are supported. Every installed SATA drive is erased
after confirmation, and storage is configured later through the official UniFi
interface.

### Why was MFA requested again?

The factory reset invalidates the original console session, and the original
Network controller can require a separate session.

### Does setup automatically update the OS or create storage?

No. Setup does not start a firmware installation, and the converter leaves
storage-pool creation to you in UniFi Drive. Automatic OS and application update
schedules are disabled, including schedules supplied during Setup and Merge or
restored on reboot. Use Control Plane for manual Drive updates; OS firmware
updates are not supported by this fixed release.

### When is temporary SSH removed?

After official console setup and service validation, the converter rotates the
temporary SSH password and disables SSH. Creating a storage pool is not required
for this cleanup. A cleanup failure is not a successful finalized setup. If
diagnostics are needed after native setup has disabled SSH, temporarily enable
it again in Control Plane.

### Does this flash a UNAS bootloader or rewrite EEPROM?

No. The conversion preserves the UNVR recovery environment and EEPROM. It does
not install a UNAS bootloader or change the physical hardware identity. When
normalizing a different OS release to 5.1.33, Ubiquiti's stock updater can also
replace the UNVR bootloader and reset its redundant environment.

Normalization to signed UNVR 5.1.33 can apply the newer U-Boot
build contained in Ubiquiti's matching signed UNVR 5.1.33 image. It does not
write a UNAS bootloader, recovery kernel, recovery environment, or EEPROM.

### How do I return to the stock UNVR experience?

Factory reset the converted console from the web-based UniFi Site Manager. The
device will restart through its preserved physical UNVR firmware and return to
the normal UNVR setup flow. This reset permanently erases the converted console
configuration and all data on its installed SATA drives, so copy anything you
want to keep before starting it.

### Are future dashboard updates guaranteed to work?

No. This converter installs the fixed OS 5.1.33 baseline and blocks subsequent
OS firmware updates. The manual Drive 4.3.10-to-4.4.9 update has been verified,
but future application releases can change dependencies, migrations, or
hardware requirements. Unknown Drive versions are refused by the compatibility
launcher rather than started without a validated profile.

The converter installs the exact APT repository-validity policy shipped by the
signed UNAS Pro 5.1.33 image. UniFi Core needs this policy for its normal
package-index refresh now that the underlying Debian 11 repository metadata has
passed its original validity period. Package signature verification remains
enabled. The converter verifies the policy content, ownership, mode, and
SHA-256 hash. The boot-time profile guard checks that the policy remains intact;
it does not authorize an OS update.

## Review the converter

The installer is plain Bash with an embedded, hash-verified helper archive:

```bash
less convert.sh
shasum -a 256 convert.sh
./convert.sh --help
```

Compare release checksums against your downloaded file before execution.

## Contributing and support

Bug reports and narrowly scoped pull requests are welcome. Include reproducible,
sanitized output. This project cannot provide Ubiquiti warranty service or
guarantee data recovery.

## License

Licensed under the [MIT License](LICENSE).
