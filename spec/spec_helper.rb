require 'puppetlabs_spec_helper/module_spec_helper'
require 'rake'

if (RUBY_VERSION.split('.').map{|s|s.to_i} <=> [2,0,0]) >= 0
  require 'simplecov'

  SimpleCov.start do
    add_filter "/fixtures/"
  end
end

ENV['STRICT_VARIABLES'] = 'no' # TODO: make the code using STRICT_VARIABLES pass

# This code is being added as a recommended workaround
# because of a known issue discussed here:
# https://github.com/puppetlabs/puppet/pull/3114
if Puppet.version < "4.0.0"
  fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
  Dir["#{fixture_path}/modules/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.pattern = FileList[c.pattern].exclude(/^spec\/fixtures/)
  c.hiera_config  = File.expand_path(File.join(__FILE__, '..', 'hiera/hiera.yaml'))
end

Puppet::Util::Log.level = :warning
Puppet::Util::Log.newdestination(:console)
