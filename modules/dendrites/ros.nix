# ros — ROS 2 on this machine, for driving robots on the LAN (the TurtleBot 4,
# a Create 3 base with a Pi, is the one it was added for). System-only: CLI tools, a binary cache
# and a firewall hole, no service.
{
  nixos =
    { pkgs, inputs, ... }:
    let
      # From the overlay's own nixpkgs, not ours — see the input in flake.nix.
      # The distro must match the robot's firmware (Create 3 web UI → About).
      ros = inputs.nix-ros-overlay.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rosPackages.humble;
    in
    {
      # The overlay's buildEnv wraps every binary with the ROS environment, so
      # `ros2` works from any shell without sourcing a setup.bash.
      environment.systemPackages = [
        (ros.buildEnv {
          paths = with ros; [
            ros-core
            teleop-twist-keyboard
            irobot-create-msgs
            # TurtleBot 4 desktop side: camera viewer, SLAM, RViz.
            rqt-image-view
            image-transport-plugins
            turtlebot4-navigation
            turtlebot4-viz
            rmw-fastrtps-cpp
            rmw-cyclonedds-cpp
          ];
        })
        pkgs.colcon
      ];

      nix.settings = {
        substituters = [ "https://ros.cachix.org" ];
        trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
      };

      # Fast DDS ports for the TurtleBot 4's domain 22: each domain owns the 250
      # ports from 7400 + 250 × ID, so 12900–13149.
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 12900;
          to = 13149;
        }
      ];
    };
}
