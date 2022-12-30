{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      formatter = pkgs.alejandra;

      packages = rec {
        default = ykfde;

        ykfde = with pkgs; let
          dependencies = [
            coreutils
            cryptsetup
            openssl
            parted
            pbkdf2-sha512
            yubikey-personalization
          ];
        in
          stdenv.mkDerivation {
            name = "ykfde";
            version = "latest";
            src = self;
            nativeBuildInputs = [makeWrapper];
            buildPhase = "cp ${./ykfde.sh} ykfde && chmod +x ykfde.sh";
            installPhase = "install -Dt $out/bin ykfde";
            postFixup = "wrapProgram $out/bin/ykfde --set PATH ${lib.makeBinPath dependencies}";
          };

        pbkdf2-sha512 = let
          src = "${nixpkgs}/nixos/modules/system/boot/pbkdf2-sha512.c";
        in
          with pkgs;
            stdenv.mkDerivation {
              name = "pbkdf2-sha512";
              version = "latest";
              buildInputs = [openssl];
              src = self;
              buildPhase = "cc -O3 -I${openssl.dev}/include -L${openssl.out}/lib ${src} -o pbkdf2-sha512 -lcrypto";
              installPhase = "mkdir -p $out/bin && install -m755 pbkdf2-sha512 $out/bin/pbkdf2-sha512";
            };
      };
    });
}
