control 'AMZL-02-740600' do
  title 'For Amazon Linux 2 operating systems using DNS resolution, at least two name servers must be
    configured.'
  desc 'To provide availability for name resolution services, multiple redundant name servers are mandated. A
    failure in name resolution could lead to the failure of security functions requiring name resolution, which may
    include time synchronization, centralized authentication, and remote system logging.'
  desc 'check', %q(Determine whether the system is using local or DNS name resolution with the following command:
    # grep hosts /etc/nsswitch.conf
    hosts: files dns
    If the DNS entry is missing from the host's line in the "/etc/nsswitch.conf" file, the "/etc/resolv.conf" file must
    be empty.
    Verify the "/etc/resolv.conf" file is empty with the following command:
    # ls -al /etc/resolv.conf
    -rw-r--r-- 1 root root 0 Aug 19 08:31 resolv.conf
    If local host authentication is being used and the "/etc/resolv.conf" file is not empty, this is a finding.
    If the DNS entry is found on the host's line of the "/etc/nsswitch.conf" file, verify the operating system is
    configured to use two or more name servers for DNS resolution.
    Determine the name servers used by the system with the following command:
    # grep nameserver /etc/resolv.conf
    nameserver 192.168.1.2
    nameserver 192.168.1.3
    If less than two lines are returned that are not commented out, this is a finding.
    Verify that the "/etc/resolv.conf" file is immutable with the following command:
    # sudo lsattr /etc/resolv.conf
    ----i----------- /etc/resolv.conf
    If the file is mutable and has not been documented with the Information System Security Officer (ISSO), this is a
    finding.)
  desc 'fix', 'Configure the operating system to use two or more name servers for DNS resolution.
    If running outside the AWS environment (on-prem), edit the "/etc/resolv.conf" file to uncomment or add the two or 
    more "nameserver" option lines with the IP address of local authoritative name servers. 
    If local host resolution is being performed, the "/etc/resolv.conf" file must be empty. An empty "/etc/resolv.conf" 
    file can be created as follows:
    # echo -n > /etc/resolv.conf

    If running an EC2 Instance in the AWS environment, the "/etc/resolv.conf" is generated at boot time based on settings 
    in the VPC DHCP Option Set. The default Option Set uses the Route 53 Resolver is located at 169.254.169.253 (IPv4) or
    fd00:ec2::253 (IPv6). Additional DNS resolvers require the creation of a custom DHCP Option Set. From the VPC Service 
    page select "DHCP Option Set" under the "Virtual Private Cloud" menue. Once the set has been created, "Edit VPC 
    Settings" and select the new Option Set.
    
    In either case make the file immutable with the following command:
    # chattr +i /etc/resolv.conf
    If the "/etc/resolv.conf" file must be mutable, the required configuration must be documented with the Information
    System Security Officer (ISSO) and the file must be verified by the system file integrity tool.'
  impact 0.3
  tag severity: 'low'
  tag gtitle: 'SRG-OS-000480-GPOS-00227'
  tag stig_id: 'AMZL-02-740600'
  tag cci: ['CCI-000366']
  tag nist: ['CM-6 b']
  tag subsystems: ['dns', 'resolv']
  tag 'host'
  tag 'container'

  dns_in_host_line = parse_config_file('/etc/nsswitch.conf',
                                       {
                                         comment_char: '#',
                                         assignment_regex: /^\s*([^:]*?)\s*:\s*(.*?)\s*$/
                                       }).params['hosts'].include?('dns')

  unless dns_in_host_line
    describe 'If `local` resolution is being used, a `hosts` entry in /etc/nsswitch.conf having `dns`' do
      subject { dns_in_host_line }
      it { should be false }
    end
  end

  unless dns_in_host_line
    describe 'If `local` resoultion is being used, the /etc/resolv.conf file should' do
      subject do
        parse_config_file('/etc/resolv.conf', { comment_char: '#' }).params
      end
      it { should be_empty }
    end
  end

  nameservers = parse_config_file('/etc/resolv.conf',
                                  { comment_char: '#' }).params.keys.grep(/nameserver/)

  if dns_in_host_line
    describe "The system's nameservers: #{nameservers}" do
      subject { nameservers }
      it { should_not be nil }
    end
  end

  if dns_in_host_line
    describe 'The number of nameservers' do
      subject { nameservers.count }
      it { should cmp >= 2 }
    end
  end

  describe '/etc/resolv.conf should be immutable -- file attributes' do
    subject { command('lsattr /etc/resolv.conf').stdout }
    it { should match /i/ }
  end
end
