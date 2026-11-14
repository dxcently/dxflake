# offsec — a Kali-style kit for offensive security: recon, web, exploitation,
# passwords, packet capture and reverse engineering.
#
# One group, everything in it; a host trims what it does not want with
# `habit.dendrites.<name>.enable = false`. Wireless tooling (aircrack-ng,
# bettercap) is left out until a host needs it. Disk forensics stays in
# `forensic-tools`; reverse engineering lives here.
#
# `wireshark` is a dendrite, not a package line: live capture needs the setcap
# dumpcap wrapper and the `wireshark` group that programs.wireshark provides.
{
  description = "Offensive security, Kali-style: recon, web, exploitation, passwords, capture and reverse engineering.";

  system.members = [
    # recon
    "nmap"
    "amass"
    "subfinder"
    "theharvester"

    # web
    "burpsuite"
    "zap"
    "sqlmap"
    "ffuf"
    "gobuster"
    "nuclei"

    # exploitation and network
    "metasploit"
    "exploitdb"
    "responder"
    "netcat-openbsd"
    "wireshark"

    # passwords
    "hashcat"
    "john"
    "thc-hydra"
    "seclists"

    # reverse engineering
    "ghidra"
    "radare2"
    "binwalk"
  ];
}
