# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  # Variables:
  s.name = "gem2arch"
  s.version = "0.0.7"
  s.description = "A version of gem2arch by crabtw that creates an ArchLinux PKGBUILD from a ruby gem"
  s.summary = "Creates an ArchLinux PKGBUILD from a ruby gem"
  s.authors = ["Ari Mizrahi" "Evan Teitelman" "Jeremy Lynch"]
  s.email = "blackarchlinux@gmail.com"
  s.homepage = "https://github.com/BlackArch/gem2arch"
  s.license = "GPL-3"
  
  # Pragmatically Gathered
  s.executables = "gem2arch"
  s.files = Dir["{lib,bin}/**/*"]
  s.files += [File.basename(__FILE__), "Gemfile", "README.md"]
  s.require_paths = ["lib"]
  
  # Dependencies
  #s.add_dependency("net-dns", "~> 0.8.0")
end
