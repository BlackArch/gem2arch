require 'digest/md5'
require 'digest/sha1'

module Gem2arch
  #
  # Core methods for Gem2arch to download gem specifications and build
  # PKGBUILD files compatible for ArchLinux makepkg
  #
  class Core

    # Make sure we're running ruby 1.9.3 or higher
    def initialize
      unless RUBY_VERSION >= '1.9.3'
        puts "You need ruby >= 1.9.3 to run gem2arch"
        exit
      end
    end

    # Download the gem and return specification information
    # @params [String] gemname is the name of the gem to download
    # @params [String] gemver is the version of the gem to download - default nil
    # @return [Gem::Specification] gem specification object
    def download( gemname, gemver=nil )
      # If gem version is not passed set it
      # to any version greater than 0
      version = gemver || '>=0'
      # Get gem requirement object
      requirement = Gem::Requirement.default
      # Get gem dependency object
      depends = Gem::Dependency.new( gemname, version )
      # Fetch gem specification
      begin
        spec_and_source = Gem::SpecFetcher.fetcher.spec_for_dependency( depends, requirement )
      rescue
        puts "I can't find any gem by the name #{gemname}"
        exit
      end
      # Get gem specification info
      spec = spec_and_source[0][0][0]
      # Get source URI
      source_uri = spec_and_source[0][0][1]
      # Quit if we don't have a spec, we can't continue without it
      # it probably means the gem doesn't exist in rubygems.org
      exit if spec.nil?
      # Download the .gem file
      system( "gem fetch #{gemname}" )

      return spec
    end

    # Hash a file and return it's MD5 or SHA1 value
    # @params [String] file is spec filename
    # @params [Symbol] type is :MD5 or :SHA1
    # @return [String] hash value of passed file parameter
    def digest( file, type )
      # Get MD5 || SHA1 object depending on [type]
      hashv = Digest::MD5.new if type == :MD5
      hashv = Digest::SHA1.new if type == :SHA1
      # Open the file and generate hash
      # in 1024 bit chunks
      File.open( file ) do |chunks|
        while buffer = chunks.read(1024)
          hashv << buffer
        end
      end

      return hashv.to_s
    end

    # Build the PKGBUILD file using the downloaded specification
    # @params [Gem::Specification] spec is gem specification object
    def build( spec, archdepends=[] )
      # Set arch=() value of PKGBUILD
      spec.extensions.empty? ? arch = "'any'" : arch = "'i686' 'x86_64'"
      # Calculate digest
      md5sum = digest( "#{spec.full_name}.gem", :MD5 )
      # Get gem dependencies
      depends = spec.runtime_dependencies
      # Modify [Array] depends if it is not empty
      unless depends.empty?
        # Break [Array] depends to modify each element
        depends.map do |dep|
          next if dep.to_s.include?('(>= 0)')
          # For each dependency we need to modify the comparison
          # symbol used to be compatible with PKGBUILD
          dep.requirement.requirements.map do |compare, version|
            # Modify the comparision symbol for PKGBUILD
            compare = '>=' if compare == '~>'
            # Replace the entire string for PKGBUILD
            archdepends << "'ruby-#{dep.name}#{compare}#{version}'"
          end
        end
      end

      # Build the gem parameters hash
      params = {
        name:         spec.name,
        version:      spec.version,
        website:      spec.homepage,
        description:  spec.summary,
        license:      spec.license,
        arch:         arch,
        md5sum:       md5sum,
        depends:      archdepends.join(" ")
      }

      pkgbuild( params )
    end

    private

      # Generate the PKGBUILD file
      # @params [Hash] gem contains all parameters required to generate the PKGBUILD file
      def pkgbuild( gem )
        if gem[:license] == ""
			gem[:license] = "custom:unknown"
        end
        File.open( 'PKGBUILD', 'w' ) do |line|
          line.puts "pkgname=ruby-#{gem[:name]}"
          line.puts "pkgver=#{gem[:version]}"
          line.puts "pkgrel=0"
          line.puts "pkgdesc=\"#{gem[:description]}\""
          line.puts "arch=(#{gem[:arch]})"
          line.puts "license=('#{gem[:license]}')"
          line.puts "makedepends=('ruby')"
          line.puts "depends=(#{gem[:depends]})" unless gem[:depends].empty?
          line.puts "url='#{gem[:website]}'"
          line.puts "source=(\"http://rubygems.org/downloads/#{gem[:name]}-$pkgver.gem\")"
          line.puts "md5sums=('#{gem[:md5sum]}')"
          line.puts "noextract=(\"#{gem[:name]}-$pkgver.gem\")"
          line.puts ""
          line.puts "package() {"
          line.puts "\s\scd \"$srcdir\""
          line.puts "\s\slocal _gemdir=$(ruby -e 'puts Gem.default_dir')"
          line.puts "\s\sif \[[ $CARCH == arm* ]] \; then"
          line.puts "\s\s\s\sgem install --no-rdoc --no-ri --no-user-install --ignore-dependencies -i \"${pkgdir}${_gemdir}\" -n \"$pkgdir/usr/bin\" #{gem[:name]}-$pkgver.gem"
          line.puts "\s\selse"
          line.puts "\s\s\s\sgem install --ignore-dependencies --no-user-install -i \"$pkgdir$_gemdir\" -n \"$pkgdir/usr/bin\" #{gem[:name]}-$pkgver.gem"
          line.puts "\s\sfi"
          line.puts "}"
        end
      end
  end
end
