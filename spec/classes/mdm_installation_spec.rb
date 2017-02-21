require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe 'scaleio::mdm::installation', :type => 'class' do
  # facts definition
  let(:facts_default) do
    {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '7.2',
        :operatingsystemmajrelease => '7',
        :concat_basedir => '/var/lib/puppet/concat',
        :is_virtual => false,
        :ipaddress => '10.0.0.20',
        :interfaces => 'eth0',
        :ipaddress_eth0 => '10.0.0.20',
        :fqdn => 'node1.example.com',
        :kernel => 'linux',
        :architecture => 'x86_64',
    }
  end
  let(:facts) { facts_default }

  # pre_condition definition
  let(:pre_condition) do
    [
        "Exec{ path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin' }",
        "include scaleio"
    ]
  end

  describe 'with standard' do
    it { should compile.with_all_deps }

    it { is_expected.to contain_file_line('scaleio::mdm::installation::actor').with(
        :path => '/opt/emc/scaleio/mdm/cfg/conf.txt',
        :match => '^actor_role_is_manager=',
        :line => 'actor_role_is_manager=0',
    ).that_notifies('Exec[scaleio::mdm::installation::restart_mdm]') }

    it { is_expected.to contain_exec('scaleio::mdm::installation::restart_mdm').with(
        :command => 'systemctl restart mdm.service; sleep 15',
        :refreshonly => true,
    ) }

    it { is_expected.to contain_package_verifiable('EMC-ScaleIO-mdm').with(
        :version => 'installed',
        :manage_package => true
    ) }
  end

  describe 'as MDM' do
    let(:params) { {:is_tiebreaker => false} }

    it { is_expected.to contain_file_line('scaleio::mdm::installation::actor').with(
        :path => '/opt/emc/scaleio/mdm/cfg/conf.txt',
        :match => '^actor_role_is_manager=',
        :line => 'actor_role_is_manager=1',
        :require => 'Package_verifiable[EMC-ScaleIO-mdm]',
    ).that_notifies('Exec[scaleio::mdm::installation::restart_mdm]') }

    it { is_expected.to contain_exec('scaleio::mdm::installation::restart_mdm').with(
        :command => 'systemctl restart mdm.service; sleep 15',
        :refreshonly => true,
    ) }

    it { is_expected.to contain_package_verifiable('EMC-ScaleIO-mdm').with(
        :version => 'installed',
        :manage_package => true
    ) }
  end

  describe 'should not update SIO packages' do
    let(:facts) { facts_default.merge({:package_emc_scaleio_mdm_version => '1'}) }

    it { is_expected.to contain_package_verifiable('EMC-ScaleIO-mdm').with(
        :version => 'installed',
        :manage_package => false
    ) }
  end

  describe 'with consul as TB' do
    let(:facts) { facts_default.merge({:fqdn => 'use_consul.example.com'}) }

    let(:params) { {:mdm_tb_ip => '1.1.1.1'} }

    it { is_expected.to contain_class('consul') }

    it { is_expected.to contain_consul_kv('scaleio/sysname/cluster_setup/1.1.1.1').with(
        :value => 'ready',
        :require => 'Exec[scaleio::mdm::installation::restart_mdm]',
    ) }
  end

  describe 'with consul as MDM' do
    let(:facts) { facts_default.merge({:fqdn => 'use_consul.example.com'}) }

    let(:params) { {:mdm_tb_ip => '2.2.2.2', :is_tiebreaker => false} }

    it { is_expected.to contain_class('consul') }

    it { is_expected.to contain_consul_kv('scaleio/sysname/cluster_setup/2.2.2.2').with(
        :value => 'ready',
        :require => 'Exec[scaleio::mdm::installation::restart_mdm]',
    ) }
  end
end
