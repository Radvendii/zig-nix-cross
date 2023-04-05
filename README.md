zig can't cross-compile in a nix build
Run
```
nix build .#pkg-zig-native # builds
nix build .#pkg-zig-cross # fails; can't find libconfig
nix build .#pkg-meson-native # builds
nix build .#pkg-meson-cross # builds
```
