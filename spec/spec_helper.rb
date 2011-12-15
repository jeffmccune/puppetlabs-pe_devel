require 'puppet'
require 'rubygems'
require 'rspec-puppet'

RSpec.configure do |c|
  c.module_path = File.join(File.dirname(__FILE__), '../../')
  # REVISIT This nees to be an empty file, rspec-puppet will always import it.
  c.manifest = File.join(File.dirname(__FILE__), 'fixtures', 'manifests', 'site.pp')
end
