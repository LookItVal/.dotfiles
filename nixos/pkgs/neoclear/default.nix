# neoclear: `clear` with a braille rain animation. Not in nixpkgs.
# https://codeberg.org/ftranschel/neoclear
#
# Upstream has no Cargo.lock (and no dependencies), so ./Cargo.lock was
# generated with `cargo generate-lockfile`. To update: bump rev, set
# hash = lib.fakeHash, build, and paste the hash from the error.
{ lib, rustPlatform, fetchzip }:
rustPlatform.buildRustPackage {
  pname = "neoclear";
  version = "0.1.0-unstable-2026-10-27";

  src = fetchzip {
    url = "https://codeberg.org/ftranschel/neoclear/archive/7c5cb7d164e9113e31d43c87589e1d847e31815b42e21f4c750e1da7bc746186.tar.gz";
    hash = "sha256-lQMpG5Vt/3+xP2YpshntRlhA8EkFYNS1GQeYborCm70=";
  };

  cargoLock.lockFile = ./Cargo.lock;
  postPatch = "ln -s ${./Cargo.lock} Cargo.lock";

  meta = {
    description = "Clear the terminal with a rain of braille glyphs";
    homepage = "https://codeberg.org/ftranschel/neoclear";
    license = lib.licenses.gpl3Plus;
    mainProgram = "neoclear";
  };
}
