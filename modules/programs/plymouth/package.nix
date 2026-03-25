# TODO: refactor upstream plymouth derivation to support building without udev
{
  lib,
  plymouth,
  gtk3,
  libdrm,
  libevdev,
  libpng,
  libxkbcommon,
  pango,
  xkeyboard_config,
  udev,
  udevSupport ? true,
  fetchpatch,
}:
plymouth.overrideAttrs (o: {
  buildInputs = [
    gtk3
    libdrm
    libevdev
    libpng
    libxkbcommon
    pango
    xkeyboard_config
  ]
  ++ lib.optionals udevSupport [ udev ];

  mesonFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "-Dbackground-color=0x000000"
    "-Dbackground-start-color-stop=0x000000"
    "-Dbackground-end-color-stop=0x000000"
    "-Drelease-file=/etc/os-release"
    "-Drunstatedir=/run"
    "-Druntime-plugins=false"
    "-Dsystemd-integration=false"
    "-Dudev=${if udevSupport then "enabled" else "disabled"}"
  ];

  patches = o.patches or [ ] ++ [
    (fetchpatch {
      name = "plymouth-no-udev.patch";
      url = "https://gitlab.freedesktop.org/aanderse/plymouth/-/commit/f1ce78764482699b28f60c89af1a071ea0ae13ca.patch";
      hash = "sha256-t5xt/scO8mVwESU8pFPTSXILd0FhmG/XRZ8O/4baQB8=";
    })
  ];
})
