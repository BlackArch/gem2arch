require 'gem2arch/core'
require 'optparse'
require 'fileutils'
require 'tmpdir'

module Gem2arch

  def self.start
    options = { 
      gem:        nil,
      version:    nil
    }

    OptionParser.new do |opts|
      opts.banner = "gem2arch 0.0.7 (https://www.github.com/codemunchies/gem2arch)"
      opts.banner += "Usage: gem2arch [options]"

      opts.on("--build [STRING]", "Gem to download and generate PKGBUILD for") do |gem|
        options[:gem] = gem
      end

      opts.on("--version [STRING]", "OPTIONAL: target specific version") do |ver|
        options[:version] = ver
      end
    end.parse!

    if options[:gem]
      # Store paths
      tmpdir = Dir.mktmpdir
      basedir = Dir.pwd

      begin
        # Get [Gem2arch] object
        gem2arch = Gem2arch::Core.new
        # Jump into tmpdir
        Dir.chdir( "#{tmpdir}" )
        # Download the gem and store spec information
        gemspec = gem2arch.download( options[:gem], options[:version] )
        # Generate the PKGBUILD
        gem2arch.build( gemspec )
        # Move the PKGBUILD from tmpdir
        FileUtils.mv( 'PKGBUILD', "#{basedir}" )
      ensure
        # Clean up
        FileUtils.remove_entry_secure tmpdir
      end
    else
      # Something
    end
  end
end
