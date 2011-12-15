require 'spec_helper'

# Note, rspec-puppet determines the class name from the top level describe
# string.
describe 'pe_devel' do
  # Default Facts
  before(:all) do
    @facter_facts = {
      'osfamily'      => 'RedHat',
      'puppetversion' => '2.7.6 (Puppet Enterprise 2.0.0)',
    }
  end
  let(:facts) do
    @facter_facts
  end
  # The most essential test of the catalog
  it { should contain_class 'pe_devel' }

  describe 'on redhat el6 os families' do
    # This is the expected content of templates when lsbmajdistrelease is unavailable
    let(:missing_content) do
      "# Contents not yet available.  Please run Puppet again.\n"
    end
    it { should contain_class   'pe_devel::redhat' }
    it { should contain_package 'gcc' }
    it { should contain_package 'wget' }
    it { should contain_package 'curl' }
    it { should contain_package 'glibc-devel' }
    it { should contain_package 'redhat-lsb' }

    describe 'with lsbmajdistrelease available' do
      let(:facts) do
        @facter_facts.merge({'lsbmajdistrelease' => '6'})
      end
      it { should_not contain_file('puppetenterprise.repo').with_content(missing_content) }
      it { should contain_package 'pe-ruby-devel' }
      it do
        pending "REVISIT - https://github.com/rodjek/rspec-puppet/pull/17 "
        should contain_file('puppetenterprise.repo').with_content(/baseurl=http/)
        should contain_file('puppetenterprise.repo').with_content(/pe_base/)
        should contain_file('puppetenterprise.repo').with_content(/pe_updates/)
        should contain_file('puppetenterprise.repo').with_content(/pe_extras/)
      end
    end

    describe 'without lsbmajdistrelease available' do
      let(:facts) do
        my_facts = @facter_facts.dup
        my_facts.delete 'lsbmajdistrelease'
        my_facts
      end
      it { should contain_file('puppetenterprise.repo').with_content(missing_content) }
      it { should_not contain_package 'pe-ruby-devel' }
    end
  end

  describe 'on debian os families' do
    let(:facts) do
      @facter_facts.merge({ 'osfamily' => 'Debian' })
    end
    it { should contain_notify 'pe_devel unimplemented' }
    it { should_not contain_class 'pe_devel::redhat' }
  end
end
