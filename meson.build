project('pkg-meson', 'c')

cc = meson.get_compiler('c')

libconfig_dep = dependency('libconfig')

executable(
  'pkg-meson',
  'main.c',
  install: true,
  dependencies: [ libconfig_dep ]
)
