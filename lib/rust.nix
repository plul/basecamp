{
  mkStable =
    { pkgs, extensions }: pkgs.rust-bin.stable.latest.minimal.override { inherit extensions; };

  mkBeta = { pkgs, extensions }: pkgs.rust-bin.stable.latest.minimal.override { inherit extensions; };

  mkNightly =
    { pkgs, extensions }:
    (pkgs.rust-bin.selectLatestNightlyWith (
      toolchain: toolchain.minimal.override { inherit extensions; }
    ));
}
