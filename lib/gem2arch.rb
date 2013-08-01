require 'digest/md5'
require 'digest/sha1'

# Download the gem and return specification information
# @params [String] gemname is the name of the gem to download
# @params [String] gemver is the version of the gem to download - default nil
# @return [Array] gem specification
def download( gemname, gemver=nil )
  # If gem version is not passed set it
  # to any version greater than 0
  version = gemver || ">=0"
  # Get gem requirement object 
  requirement = Gem::Requirement.default
  # Get gem dependency object 
  depends = Gem::Dependency.new( gemname, version )
  # Fetch gem specification
  spec_and_source = Gem::SpecFetcher.fetcher.spec_for_dependency( depends, requirement )
  # Get gem specification info
  spec = spec_and_source[0][0][0]
  # Get source URI
  source_uri = spec_and_source[0][0][1]
  # Quit if we don't have a spec, we can't continue without it
  # it probably means the gem doesn't exist in rubygems.org
  exit if spec.nil?
  
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


