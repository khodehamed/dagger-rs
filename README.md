# dagger-rs 0.2.1

Linux tunnel (x86_64). This package is the Rust rewrite shipped in `DaggerConnect-4.2.8-stable-resync`. It does not speak the original DaggerConnect protocol.

## Install

On each Ubuntu/Debian server, as root:

```bash
curl -fsSL https://raw.githubusercontent.com/khodehamed/dagger-rs/main/install.sh | sudo bash
```

The installer checks the bundle checksum, installs the binary, and opens the setup menu. Next time:

```bash
sudo /usr/local/bin/dagger-setup
```

Full project notes: [files-to-upload/README.md](files-to-upload/README.md). Persian tunnel walkthrough: [howto-tunnel-fa.txt](howto-tunnel-fa.txt).
