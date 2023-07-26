control 'AMZL-02-740201' do
  title 'The Amazon Linux 2 operating system must implement virtual address space randomization.'
  desc "Address space layout randomization (ASLR) makes it more difficult for an attacker to predict the location of
    attack code he or she has introduced into a process's address space during an attempt at exploitation. Additionally,
    ASLR also makes it more difficult for an attacker to know the location of existing code in order to repurpose it
    using return-oriented programming (ROP) techniques."
  desc 'check', 'Verify the operating system implements virtual address space randomization.

     # grep -r kernel.randomize_va_space /run/sysctl.d/* /etc/sysctl.d/* /usr/local/lib/sysctl.d/* /usr/lib/sysctl.d/* /lib/sysctl.d/* /etc/sysctl.conf 2> /dev/null
     kernel.randomize_va_space = 2

If "kernel.randomize_va_space" is not configured in the /etc/sysctl.conf file or or in any of the other sysctl.d directories, is commented out or does not have a value of "2", this is a finding.

Check that the operating system implements virtual address space randomization with the following command:

     # /sbin/sysctl -a | grep kernel.randomize_va_space
     kernel.randomize_va_space = 2

If "kernel.randomize_va_space" does not have a value of "2", this is a finding.

If conflicting results are returned, this is a finding.'
  desc 'fix', 'Configure the operating system implement virtual address space randomization.
    Set the system to the required kernel parameter by adding the following line to "/etc/sysctl.conf" or a config file
    in the /etc/sysctl.d/ directory (or modify the line to have the required value):
    kernel.randomize_va_space = 2
    Issue the following command to make the changes take effect:
    # sysctl --system'
  impact 0.5
  tag legacy: ['SV-92521', 'V-77825']
  tag severity: 'medium'
  tag gtitle: 'SRG-OS-000480-GPOS-00227'
  tag gid: 'V-204584'
  tag rid: 'AMZL-02-740201r880794_rule'
  tag stig_id: 'RHEL-07-040201'
  tag fix_id: 'F-4708r880793_fix'
  tag cci: ['CCI-000366']
  tag nist: ['CM-6 b']
  tag subsystems: ['aslr', 'kernel_parameter']
  tag 'host'

  if virtualization.system.eql?('docker')
    impact 0.0
    describe 'Control not applicable - Kernel config must be done on the host' do
      skip 'Control not applicable - Kernel config must be done on the host'
    end
  else
    randomize_va_space = input('randomize_va_space')
    config_file_values = command('grep -r kernel.randomize_va_space /run/sysctl.d/* /etc/sysctl.d/* /usr/local/lib/sysctl.d/* /usr/lib/sysctl.d/* /lib/sysctl.d/* /etc/sysctl.conf 2> /dev/null')
                         .stdout.strip.split("\n")
                         .map { |file| parse_config(file).params }
    config_file_values_uncompliant = config_file_values.select { |entry| entry.values != [randomize_va_space.to_s] }

    unless config_file_values_uncompliant.empty?
      describe 'All configuration files' do
        it "should set randomize_va_space to #{randomize_va_space}, or not define it at all" do
          fail_msg = "Found incorrect configuration:\n#{config_file_values_uncompliant.join("\n")}"
          expect(config_file_values_uncompliant).to be_empty, fail_msg
        end
      end
    end

    describe 'The runtime kernel parameter kernel.randomize_va_space' do
      subject { kernel_parameter('kernel.randomize_va_space') }
      its('value') { should eq randomize_va_space }
    end
  end
end
