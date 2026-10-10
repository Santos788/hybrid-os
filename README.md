# Hybrid_OS

A portable development environment that runs entirely in **RAM** from a Linux Live-USB and persists projects and settings on an **Android device (Termux)** over SSH and Rclone, leaving no traces on the host computer.

[Português](README.pt-BR.md) · **English**

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![SSH](https://img.shields.io/badge/SSH-secure-informational?style=flat-square)
![Rclone](https://img.shields.io/badge/Rclone-SFTP-3F79AD?style=flat-square)

---

## Overview

| Feature | Description |
|---|---|
| **RAM execution** | The project is copied to `/tmp` and runs in memory, giving fast read/write speeds and isolation from the host system. |
| **Remote persistence** | The Android volume is mounted via Rclone (SFTP) over an SSH tunnel on port `8022`. |
| **Automatic discovery** | The script locates the Android device on the network and validates the connection before mounting. |
| **Session cleanup** | Unmounts volumes and removes tokens and credentials from RAM on exit. |

## Architecture

```text
 ┌──────────────────────┐      SSH / Rclone (SFTP)      ┌──────────────────────┐
 │   Android / Termux   │ ◄───────────────────────────► │    Linux Live-USB    │
 │    (persistence)     │      port 8022 · same LAN     │    (RAM execution)   │
 └──────────────────────┘                               └──────────┬───────────┘
                                                                   │
                                                                   ▼
                                                        ┌──────────────────────┐
                                                        │ VS Code / Dev Tools  │
                                                        │ Post-session cleanup │
                                                        └──────────────────────┘
```

## Project structure

```text
hybrid-os/
├── scripts/
│   ├── setup.sh      # Installs and configures dependencies on the Live-USB
│   ├── boot.sh       # Discovers the IP, validates SSH, shows the menu, mounts via Rclone
│   └── cleanup.sh    # Unmounts volumes and wipes data and credentials from RAM
├── .gitignore
├── LICENSE
└── README.md
```

## Requirements

- Android device with **Termux** and the SSH server running (`sshd`)
- Computer booted from a **Linux Mint Live-USB**, on the same Wi-Fi network as the Android device

## Usage

USB drive partitions in Live environments are usually mounted with `noexec`. For that reason, the project is copied to RAM (`/tmp`) before it is executed.

### One-liner

```bash
cd ~/hybrid-os && git pull \
  && rm -rf /tmp/hybrid-os-app \
  && cp -r ~/hybrid-os /tmp/hybrid-os-app \
  && cd /tmp/hybrid-os-app \
  && bash scripts/setup.sh \
  && bash scripts/boot.sh
```

### Step by step

**1. Update the repository**

```bash
cd ~/hybrid-os && git pull
```

**2. Copy the project to RAM**

```bash
rm -rf /tmp/hybrid-os-app && cp -r ~/hybrid-os /tmp/hybrid-os-app && cd /tmp/hybrid-os-app
```

**3. Install dependencies**

```bash
bash scripts/setup.sh
```

**4. Start the bridge and VS Code**

```bash
bash scripts/boot.sh
```

**5. End the session and clean up RAM**

```bash
bash scripts/cleanup.sh
```

## Security

- **No local traces:** no sensitive data or access keys remain on the host computer's disk after shutdown.
- **Isolated environment:** runs in RAM, inside controlled temporary directories.
- **SSH identity validation:** host signatures (`known_hosts`) are checked before the volume is allowed to mount via Rclone SFTP.
- **Session sanitization:** `cleanup.sh` removes tokens and credentials from memory.

## Author

**Clayton Santos** · Backend Developer | Python | FastAPI | AppSec

[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=flat-square&logo=gmail&logoColor=white)](mailto:claytondev43@gmail.com)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/claytonsantos-backend)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/Santos788)

## License

Distributed under the license described in the [LICENSE](LICENSE) file.
