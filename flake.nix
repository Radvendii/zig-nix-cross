{
  description = "Test nix cross-compiling with zig";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    zig-in = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zig-in }:
  let
    system = "x86_64-linux";
    overlays = [(final: prev: {
      zig = zig-in.packages.${system}.master;
    })];
    pkgs-native = import nixpkgs {
      inherit system overlays;
    };
    pkgs-cross = import nixpkgs {
      inherit system overlays;
      crossSystem.config = "aarch64-unknown-linux-gnu";
    };

    pkg-zig-func = {
      stdenv,
      zig,
      pkg-config,
      libconfig,
      autoPatchelfHook
    }: stdenv.mkDerivation {
      pname = "pkg-zig";
      version = "0.0.1";

      src = self;

      nativeBuildInputs = [ zig pkg-config autoPatchelfHook ];

      buildInputs = [ libconfig ];

      buildPhase = ''
        export HOME=$TMPDIR
        zig build --prefix $prefix
      '';
    };

    pkg-meson-func = {
      stdenv,
      meson,
      ninja,
      pkg-config,
      libconfig
    }: stdenv.mkDerivation {
      pname = "pkg-meson";
      version = "0.0.1";

      src = self;
      nativeBuildInputs = [ meson ninja pkg-config ];
      buildInputs = [ libconfig ];
    };

  in {
    packages.${system} = {
      hello-native = pkgs-native.hello;
      hello-cross = pkgs-cross.hello;
      pkg-zig-native = pkgs-native.callPackage pkg-zig-func { };
      pkg-zig-cross = pkgs-cross.callPackage pkg-zig-func { };
      pkg-meson-native = pkgs-native.callPackage pkg-meson-func { };
      pkg-meson-cross = pkgs-cross.callPackage pkg-meson-func { };
    };
    devShells.${system}.default = pkgs-native.mkShell {
      buildInputs = with pkgs-native; [
        zig
        libconfig
        pkg-config
      ];
    };
  };
}
