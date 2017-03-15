require 'puppet/parameter/boolean'

Puppet::Type.newtype(:scaleio_sds) do
  @doc = "Manage ScaleIO SDS's"

  ensurable

  validate do
    validate_required(:pool_devices, :protection_domain, :ips)
  end

  newparam(:name, :namevar => true) do
    desc "The SDS name"
    validate do |value|
      fail("#{value} is not a valid value for SDS name.") unless value =~ /^[\w\-]+$/
    end
  end

  newproperty(:ips, :array_matching => :all) do
    desc "The SDS IP address/addresses"
    validate do |value|
      fail("#{value} is not a valid IPv4 address") unless IPAddr.new(value).ipv4?
    end
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:port) do
    desc "The SDS port address"
    validate do |value|
      fail("#{value} is not a valid value for SDS port.") unless value.is_a? Integer
    end
  end

  newproperty(:fault_set) do
    desc "The fault set this SDS shall be part of."
    validate do |value|
      fail("#{value} is not a valid name for the fault set name of a SDS.") unless value =~ /^[\w\-]+$/
    end
  end

  newparam(:useconsul, :boolean => true) do
    desc "Use consul to wait for SDS being available"

    defaultto false
  end

  newproperty(:ramcache_size) do
    desc "RAM cache size of the SDS in MB (-1 to disable RAM cache)"

    defaultto 128
    validate do |value|
      fail("#{value} is not a valid RAM cache size.") unless value.is_a? Integer
    end
  end

  newproperty(:pool_devices) do
    desc "Pools and the devices of the SDS"
    validate do |value|
      fail("pool_devices should be a hash with the pool name as key and an array with the devices as value.") unless value.class == Hash
    end
    def insync?(is)
      sync = true

      # Check for new pools on that SDS
      should.each do |storage_pool, devices|
        if !is.has_key?(storage_pool)
          sync = false
        end
      end

      is.each do |storage_pool, devices|
        # Check for removed pools on that SDS
        if should.has_key?(storage_pool)
          # Check for modified device list on that pool
          if devices.sort != should[storage_pool].sort
            sync = false
          end
        else
          sync = false
        end
      end
      sync
    end
  end

  newproperty(:rfcache_devices, :array_matching => :all) do
    desc "Rfcache devices of the SDS"
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:rfcache) do
    desc "Use Rfcache on SDS"

    defaultto false
  end

  newproperty(:protection_domain) do
    desc "The protection domain name"
  end

  autorequire(:scaleio_protection_domain) do
    [ self[:protection_domain] ].compact
  end

  autorequire(:scaleio_storage_pool) do
    pools = []
    self[:pool_devices].each do |storage_pool, devices|
      pools << "#{self[:protection_domain]}:#{storage_pool}"
    end
    pools
  end

  autorequire(:scaleio_fault_set) do
    "#{self[:protection_domain]}:#{self[:fault_set]}"
  end

  # helper method, pass required parameters
  def validate_required(*required_parameters)
    if self[:ensure] == :present
      required_parameters.each do |req_param|
        raise ArgumentError, "parameter '#{req_param}' is required" if self[req_param].nil?
      end
    end
  end

end

