{ ... }:
{
  # Nix-built QuickShell/bootstrap need Arch's GL stack (Nix Mesa has no DRI drivers)
  systemd.user.services.dms.Service.Environment = [
    "LIBGL_DRIVERS_PATH=/usr/lib/dri"
    "__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d"
    "LD_LIBRARY_PATH=/usr/lib"
  ];

  systemd.user.services.bootstrap.Service.Environment = [
    "LIBGL_DRIVERS_PATH=/usr/lib/dri"
    "__EGL_VENDOR_LIBRARY_DIRS=/usr/share/glvnd/egl_vendor.d"
    "LD_LIBRARY_PATH=/usr/lib"
  ];
}
