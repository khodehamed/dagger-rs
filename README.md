# dagger-rs 0.2.1

Linux tunnel (x86_64). This package is the Rust rewrite shipped in `DaggerConnect-4.2.8-stable-resync`. It does not speak the original DaggerConnect protocol.

## Install

On each Ubuntu/Debian server, as root:

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/khodehamed/dagger-rs@main/install.sh | sudo bash
```

The installer checks the bundle checksum, installs the binary, and opens a full-screen color setup page on your terminal. That still works from `curl | bash`, because the menu is attached to `/dev/tty` instead of the pipe. If there is no terminal, it prints one line and exits. Next time:

```bash
sudo dagger-setup
```

Full project notes: [files-to-upload/README.md](files-to-upload/README.md). Persian tunnel walkthrough: [howto-tunnel-fa.txt](howto-tunnel-fa.txt).
