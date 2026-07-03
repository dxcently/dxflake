{
  pkgs,
  inputs,
  ...
}: {
  programs = {
    virt-manager.enable = true;
    nm-applet.enable = true;
  };

  # Flatpak/portal plumbing — a desktop concern, not the universal floor.
  # Hyprland adds its own portal on top when that aggregation is present.
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  environment.systemPackages = with pkgs; [
    # ── Terminal & Monitors (GUI) ──
    kitty # GPU-accelerated terminal emulator
    mission-center # GUI resource monitor with GPU usage

    # ── Files & Disks (GUI) ──
    file-roller # GNOME archive manager (Thunar integration)
    gparted # graphical partition editor

    # ── Multimedia ──
    mpv # scriptable command-line media player
    vlc # cross-platform multimedia player
    wireplumber # PipeWire session and policy manager
    pavucontrol # PulseAudio/PipeWire volume control GUI
    strawberry # music player with audio CD and lyrics
    playerctl # MPRIS2 media player controller
    ffmpegthumbnailer # video thumbnails via libffmpeg
    obs-studio # screen recording and live streaming
    losslesscut-bin # lossless video/audio trimmer
    scrcpy # display and control Android devices

    # ── Networking & Web ──
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    chromium # open source web browser from Google
    qbittorrent # open-source BitTorrent client
    nicotine-plus # Soulseek peer-to-peer client
    zoom-us # video conferencing

    # ── Productivity & Knowledge ──
    obsidian # markdown personal knowledge base
    anki-bin # spaced repetition flashcards
    pear-desktop # unofficial YouTube Music client

    # ── Creative ──
    gimp3-with-plugins # GNU Image Manipulation Program
    aseprite # pixel art editor and animation
    webcamoid # webcam capture with effects
    orca-slicer # G-code slicer for 3D printing
  ];
}
