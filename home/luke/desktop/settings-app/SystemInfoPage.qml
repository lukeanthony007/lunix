import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    Flickable {
        anchors.fill: parent
        anchors.margins: 24
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            Text { text: "System Info"; color: "white"; font.pixelSize: 20; font.weight: Font.Bold }

            GlassCard {
                Layout.fillWidth: true
                title: "Hardware"

                InfoRow { label: "Hostname"; value: sysHostname.text || "..." }
                InfoRow { label: "Kernel"; value: sysKernel.text || "..." }
                InfoRow { label: "Uptime"; value: sysUptime.text || "..." }
                InfoRow { label: "CPU"; value: sysCpu.text || "..." }
                InfoRow { label: "Memory"; value: sysMem.text || "..." }
                InfoRow { label: "Disk"; value: sysDisk.text || "..." }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "NixOS"

                InfoRow { label: "NixOS Version"; value: sysNixos.text || "..." }
                InfoRow { label: "Nix Version"; value: sysNix.text || "..." }
                InfoRow { label: "Config Flake"; value: sysFlake.text || "..." }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "Desktop"

                InfoRow { label: "Compositor"; value: "Hyprland" }
                InfoRow { label: "Shell"; value: "DankMaterialShell" }
                InfoRow { label: "Terminal"; value: "foot" }
                InfoRow { label: "Editor"; value: "neovim (NvChad)" }
                InfoRow { label: "Login Shell"; value: "fish + starship" }
            }
        }
    }

    // Data collectors
    property string _dummy: ""
    Process { id: _h; running: true; command: ["hostname"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysHostname.text = data.trim() } }
    Process { id: _k; running: true; command: ["uname", "-r"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysKernel.text = data.trim() } }
    Process { id: _u; running: true; command: ["sh", "-c", "uptime -p 2>/dev/null || uptime"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysUptime.text = data.trim() } }
    Process { id: _c; running: true; command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysCpu.text = data.trim() } }
    Process { id: _m; running: true; command: ["sh", "-c", "free -h | awk '/Mem:/{print $3\"/\"$2}'"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysMem.text = data.trim() } }
    Process { id: _d; running: true; command: ["sh", "-c", "df -h / | awk 'NR==2{print $3\"/\"$2\" (\"$5\" used)\"}'"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysDisk.text = data.trim() } }
    Process { id: _n; running: true; command: ["sh", "-c", "cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"'"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysNixos.text = data.trim() } }
    Process { id: _nv; running: true; command: ["sh", "-c", "nix --version 2>/dev/null || echo 'not found'"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysNix.text = data.trim() } }
    Process { id: _f; running: true; command: ["sh", "-c", "readlink /run/current-system 2>/dev/null | head -c 40 || echo 'unknown'"]; stdout: SplitParser { splitMarker: ""; onRead: data => sysFlake.text = data.trim() } }

    Text { id: sysHostname; visible: false }
    Text { id: sysKernel; visible: false }
    Text { id: sysUptime; visible: false }
    Text { id: sysCpu; visible: false }
    Text { id: sysMem; visible: false }
    Text { id: sysDisk; visible: false }
    Text { id: sysNixos; visible: false }
    Text { id: sysNix; visible: false }
    Text { id: sysFlake; visible: false }
}
