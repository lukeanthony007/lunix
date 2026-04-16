{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        (anthropic.claude-code.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            # The extension resolves resources/native-binary/claude and passes it
            # to Node as a script. The Nix wrapper is a bash script, which causes
            # SyntaxError. Replace the symlink with a thin JS shim.
            native="$out/share/vscode/extensions/anthropic.claude-code/resources/native-binary/claude"
            if [ -L "$native" ] || [ -f "$native" ]; then
              rm "$native"
              cat > "$native" << 'SHIM'
#!/usr/bin/env node
process.env.DISABLE_AUTOUPDATER = '1';
process.env.FORCE_AUTOUPDATE_PLUGINS ??= '1';
process.env.DISABLE_INSTALLATION_CHECKS = '1';
delete process.env.DEV;
SHIM
              cat >> "$native" <<EOF
const bins = ['${pkgs.socat}/bin', '${pkgs.bubblewrap}/bin', '${pkgs.procps}/bin'];
process.env.PATH = [...bins, process.env.PATH].filter(Boolean).join(':');
await import('${pkgs.claude-code}/lib/node_modules/@anthropic-ai/claude-code/cli.js');
EOF
              chmod +x "$native"
            fi
          '';
        }))
        jnoortheen.nix-ide
        skellock.just
        tamasfe.even-better-toml
        usernamehw.errorlens
      ] ++ (with pkgs.vscode-utils; [
        (extensionFromVscodeMarketplace {
          name = "base16-themes";
          publisher = "andrsdc";
          version = "1.4.5";
          hash = "sha256-molx+cRKSB6os7pDr0U1v/Qbaklps+OvBkZCkSWEvWM=";
        })
        (extensionFromVscodeMarketplace {
          name = "beardedtheme";
          publisher = "BeardedBear";
          version = "10.1.0";
          hash = "sha256-7MkvLEadzgB7af01lYibEOqHn9bvzlpgMTEiiQBlEzA=";
        })
        (extensionFromVscodeMarketplace {
          name = "chatgpt";
          publisher = "OpenAI";
          version = "26.311.21342";
          hash = "sha256-hqNiHXg/PlfoHe27IxUIwSrXIjIZzzhhVF5fcXZ3kRw=";
        })
      ]);

      userSettings = {
        # General
        "files.autoSave" = "afterDelay";
        "files.associations" = { "*.tidal" = "haskell"; };
        "editor.formatOnSave" = true;
        "security.workspace.trust.untrustedFiles" = "open";
        "git.openRepositoryInParentFolders" = "always";
        "editor.scrollbar.horizontal" = "hidden";

        # Editor
        "editor.mouseWheelZoom" = true;
        "window.zoomLevel" = 3;
        "workbench.startupEditor" = "none";
        "editor.lineNumbers" = "off";

        # Style
        "editor.fontLigatures" = true;
        "editor.fontFamily" = "'FiraCode Nerd Font', 'monospace', monospace";
        "editor.lineHeight" = 24;
        "editor.fontWeight" = "600";

        # Terminal
        "terminal.integrated.env.linux" = {};
        "terminal.integrated.fontFamily" = "SpaceMono Nerd Font";
        "terminal.integrated.cursorStyle" = "line";
        "terminal.external.linuxExec" = "foot";

        # Library
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "explorer.confirmDragAndDrop" = false;
        "explorer.confirmPasteNative" = false;
        "explorer.confirmDelete" = false;

        # UI
        "editor.quickSuggestions" = {
          "other" = false;
          "comments" = false;
          "strings" = false;
        };
        "breadcrumbs.enabled" = false;
        "workbench.editor.showTabs" = "none";
        "terminal.integrated.smoothScrolling" = true;
        "window.menuBarVisibility" = "hidden";
        "editor.tabSize" = 2;
        "editor.minimap.enabled" = false;
        "editor.inlayHints.enabled" = "offUnlessPressed";
        "editor.stickyScroll.enabled" = false;
        "window.titleBarStyle" = "native";
        "workbench.editor.editorActionsLocation" = "hidden";
        "testing.automaticallyOpenTestResults" = "neverOpen";
        "workbench.editor.empty.hint" = "hidden";
        "workbench.activityBar.location" = "hidden";
        "terminal.integrated.stickyScroll.enabled" = false;
        "workbench.statusBar.visible" = false;
        "workbench.sideBar.location" = "right";
        "window.customTitleBarVisibility" = "never";

        # Rust
        "rust-analyzer.interpret.tests" = true;
        "rust-analyzer.testExplorer" = true;

        # Copilot
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.enable" = {
          "*" = false;
          "plaintext" = false;
          "markdown" = false;
          "scminput" = false;
        };

        # Claude
        "claudeCode.preferredLocation" = "panel";
        "claudeCode.allowDangerouslySkipPermissions" = true;

        # Chat
        "chat.agentsControl.enabled" = false;
        "chat.viewSessions.orientation" = "stacked";
        "inlineChat.lineNaturalLanguageHint" = false;

        # Theme
        "glassit.alpha" = 220;
        "workbench.colorTheme" = "Bearded Theme OLED (Experimental)";
        "workbench.colorCustomizations" = {
          "editor.background" = "#000000";
          "editorGutter.background" = "#000000";
          "editor.lineHighlightBackground" = "#0d0d0d";
          "editorLineNumber.activeForeground" = "#8a8a8a";
          "editorGroup.background" = "#000000";
          "sideBar.background" = "#000000";
          "activityBar.background" = "#000000";
          "statusBar.background" = "#000000";
          "titleBar.activeBackground" = "#000000";
          "titleBar.inactiveBackground" = "#0a0a0a";
          "tab.activeBackground" = "#000000";
          "tab.inactiveBackground" = "#0a0a0a";
          "panel.background" = "#000000";
          "terminal.background" = "#000000";
          "editorWidget.background" = "#050505";
          "minimap.background" = "#000000";
          "peekViewEditor.background" = "#000000";
        };


        # Misc
        "debug.inlineValues" = "on";
        "console-ninja.featureSet" = "Community";
        "vscode-color-picker.languages" = [
          "python" "javascript" "typescript"
          "react-typescript" "react-javascript"
        ];

        # Claude - use local harness build
        # "claudeCode.claudeProcessWrapper" = "/home/luke/Source/repos/agentic/harness/claude-code/dist/cli.mjs";
      };
    };
  };
}
