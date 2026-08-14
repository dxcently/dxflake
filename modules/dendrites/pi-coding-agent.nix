{
  pkgs,
  config,
  lib,
  username,
  ...
}:
let
  # Pinned nixpkgs ships 0.84.1 — new enough for pi extensions (e.g.
  # pi-web-access) that import `@earendil-works/pi-ai/compat` (added in 0.81.0).
  pi-coding-agent = pkgs.pi-coding-agent;

  # Startup dashboard extension: replaces pi's minimal built-in header
  # (plain "pi vX" + keybinding list) with the mascot plus live session info.
  # Auto-discovered by pi from ~/.pi/agent/extensions/. No template literals —
  # `${` would collide with Nix string interpolation.
  dashboard = ''
    // Managed by dxflake (modules/dendrites/pi-coding-agent.nix) — edits are overwritten.
    import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
    import { VERSION } from "@earendil-works/pi-coding-agent";
    import os from "node:os";

    const ART_WIDTH = 16;

    // Pads a rendered line (which may contain ANSI codes) to the art width,
    // given its visible cell count.
    function pad(line: string, visible: number): string {
      return line + " ".repeat(Math.max(0, ART_WIDTH - visible));
    }

    // The pi mascot: sideways-looking eyes over a π with a serif roof.
    function mascot(theme: Theme): string[] {
      const blue = (s: string) => theme.fg("accent", s);
      const eye = "█" + theme.fg("dim", "▌");
      const legs = blue("██") + "    " + blue("██");
      return [
        pad("     " + eye + "  " + eye, 11),
        pad("  " + blue("█".repeat(14)), 16),
        pad("     " + legs, 13),
        pad("     " + legs, 13),
        pad("     " + legs, 13),
        pad("     " + legs, 13),
      ];
    }

    function infoLines(theme: Theme, model: string, dir: string): string[] {
      const label = (s: string) => theme.fg("muted", s);
      return [
        theme.bold(theme.fg("accent", "π")) + theme.fg("dim", " v" + VERSION),
        "",
        label("model  ") + theme.fg("text", model),
        label("dir    ") + theme.fg("text", dir),
        "",
        theme.fg("dim", "/ commands · ! bash · ctrl+p models · shift+tab thinking"),
      ];
    }

    export default function (pi: ExtensionAPI) {
      pi.on("session_start", async (_event, ctx) => {
        if (ctx.mode !== "tui") return;
        const model = ctx.model ? ctx.model.provider + "/" + ctx.model.id : "no model selected";
        const dir = ctx.cwd.replace(os.homedir(), "~");
        ctx.ui.setHeader((_tui, theme) => ({
          render(_width: number): string[] {
            const art = mascot(theme);
            const info = infoLines(theme, model, dir);
            const rows = Math.max(art.length, info.length);
            const blank = " ".repeat(ART_WIDTH);
            const lines: string[] = [""];
            for (let i = 0; i < rows; i++) {
              const left = i < art.length ? art[i] : blank;
              const right = i < info.length ? info[i] : "";
              lines.push(left + "   " + right);
            }
            lines.push("");
            return lines;
          },
          invalidate() {},
        }));
      });

      pi.registerCommand("builtin-header", {
        description: "Restore pi's built-in header with keybinding hints",
        handler: async (_args, ctx) => {
          ctx.ui.setHeader(undefined);
          ctx.ui.notify("Built-in header restored", "info");
        },
      });
    }
  '';
in
{
  options.dx.pi-coding-agent.enable = lib.mkEnableOption "pi coding agent CLI";
  config = lib.mkIf config.dx.pi-coding-agent.enable {
    home-manager.users.${username} = {
      programs.pi-coding-agent = {
        enable = true;
        package = pi-coding-agent;
        # pi installs npm:* packages by shelling out to npm on startup when a
        # package declared in settings is missing from ~/.pi/agent/npm/.
        extraPackages = [ pkgs.nodejs ];
        settings = {
          # Carried over from the previously hand-managed settings.json.
          defaultProvider = "kimi-coding";
          defaultModel = "k3-256k";
          defaultThinkingLevel = "high";
          # Declared here; pi auto-installs anything missing on first launch.
          packages = [
            "npm:pi-subagents"
            "npm:pi-mcp-adapter"
            "npm:pi-web-access"
          ];
        };
      };

      home.file.".pi/agent/extensions/dashboard.ts".text = dashboard;
    };
  };
}
