# Puppet Enterprise Development Module

This module configures a system to have the resources necessary to develop
solutions on top of the Puppet Enterprise platform.

# Quick Start Install

This module needs to be installed on the Puppet Master system.  With Puppet
Enterprise already installed with the master role, these commands will put the
Puppet pe\_devel module in the correct place.

    % cd /etc/puppetlabs/puppet/modules
    % sudo puppet-module install puppetlabs-pe_devel
    Installed "puppetlabs-pe_devel-0.0.1" into directory: pe_devel
    % cd pe_devel
    % sudo puppet apply -e 'include pe_devel'

# Installation from Source

If this module is not available from the Forge or you'd like to work on it from
source, perhaps to add support for a platform the module does not currently
support you can manually build the package.  For example:

    % cd ~/src/modules/pe_devel
    % rake build
    (in /Users/jeff/src/modules/pe_devel)
    ============================================================
    Building /Users/jeff/src/modules/pe_devel for release
    ------------------------------------------------------------
    Done. Built: pkg/puppetlabs-pe_devel-0.0.1.tar.gz

Once build, the package may be installed replacing the name with the path to
the package tar.gz file.  For example:

    % cd /etc/puppetlabs/puppet/modules
    % sudo puppet-module install \
           ~jeff/src/modules/pe_devel/pkg/puppetlabs-pe_devel-0.0.1.tar.gz
    Installed "puppetlabs-pe_devel-0.0.1" into directory: pe_devel
    % cd pe_devel
    % sudo puppet apply -e 'include pe_devel'

NOTE: When frequently installing from source, make sure to clean your module
cache before installing a newly build module otherwise you may installed an
older, cached version of the module with the same name and version string.

# Puppet Enterprise Packages via YUM

This module makes the assumption that Puppet Enterprise packages are available
via YUM using the base URL of
[http://links.puppetlabs.com/puppet-enterprise](http://links.puppetlabs.com/puppet-enterprise)
At the time of writing this URL re-directs to a Puppet Labs internal system
because the Puppet Enterprise YUM repository is not currently available to the
public.

If you have Puppet Enterprise, it's possible to make the packages available
using createrepo on an enterprise linux system like this example illustrates:

    % cd /var/www/html
    % mkdir -p puppet-enterprise/yum/2.0.0/base/el6/i386
    % rsync -avxHP /tmp/puppet-enterprise-2.0.0-all/packages/el-6-i386/ \
        /var/www/html/puppet-enterprise/yum/2.0.0/base/el6/i386/
    % cd /var/www/html/puppet-enterprise/yum/2.0.0/base/el6/i386/
    % createrepo .

And then configure the module to use your own URL like so:

    % sudo -s
    # export FACTER_puppetenterprise_baseurl="http://yum.acme.lan/puppet-enterprise"
    # puppet apply -v -e 'include pe_devel'

NOTE: The module is currently using 2.0.0 directly in the
puppetenterprise.repo.erb template.  A good place to improve the module would
be to add a PE version fact to stdlib and make the URL more dynamic based on
the Puppet Enterprise version the module is running on.

# Expected Behavior

If everything is setup correctly you should see these resources managed:

    root@pe-centos6:~# puppet apply -v -e 'include pe_devel'
    info: Loading facts in facter_dot_d
    info: Loading facts in facter_dot_d
    info: Applying configuration version '1323993947'
    notice: /Stage[main]/Pe_devel::Redhat/Package[epel-release]/ensure: created
    notice: /Stage[main]/Pe_devel::Redhat/File[puppetenterprise.repo]/ensure: defined content as '{md5}d044e92b6d23cd42efdca8d4cecb08c4'
    notice: /Stage[main]/Pe_devel::Redhat/Package[createrepo]/ensure: created
    notice: /Stage[main]/Pe_devel::Redhat/Package[glibc-devel]/ensure: created
    notice: /Stage[main]/Pe_devel::Redhat/Package[wget]/ensure: created
    notice: /Stage[main]/Pe_devel::Redhat/Package[gcc]/ensure: created
    notice: /Stage[main]/Pe_devel::Redhat/Package[pe-ruby-devel]/ensure: created
    notice: Finished catalog run in 22.97 seconds

If the `pe-ruby-devel` package has trouble it likely means the node being
managed does not have access to the system hosting the Puppet Enterprise
packages referenced by the puppetenterprise\_baseurl parameter.  If the
repository containing the `pe-ruby-devel` package is not available to the node
being managed you can expect an error like this:

    info: Loading facts in facter_dot_d
    info: Loading facts in facter_dot_d
    info: Applying configuration version '1323994960'
    err: /Stage[main]/Pe_devel::Redhat/Package[pe-ruby-devel]/ensure: change from absent to latest failed: Could not update: Execution of '/usr/bin/yum -d 0 -e 0 -y install pe-ruby-devel' returned 1: 

    Error Downloading Packages:
      pe-ruby-devel-1.8.7.302-4.pe.el6.i386: failure: pe-ruby-devel-1.8.7.302-4.pe.el6.i386.rpm from pe_base: [Errno 256] No more mirrors to try.

     at /etc/puppetlabs/puppet/modules/pe_devel/manifests/init.pp:127
    notice: /Stage[main]/Pe_devel/Anchor[pe_devel::end]: Dependency Package[pe-ruby-devel] has failures: true
    warning: /Stage[main]/Pe_devel/Anchor[pe_devel::end]: Skipping because of failed dependencies
    notice: Finished catalog run in 3.33 seconds

# RSpec Testing

This module has behavior tests written using [RSpec
2](https://www.relishapp.com/rspec).  The goal of these tests are to validate
the expected behavior of the module.  As more features and platform support are
added to this module the tests provide an automated way to validate the
expectations previous contributors have specified.

In order to validate the behavior, please run the `rake spec` task.

    % rake spec
    (in /Users/jeff/vms/puppet/modules/foo)
    .
    Finished in 0.31279 seconds
    1 example, 0 failures

## RSpec Testing Requirements

The spec tests require the `rspec-puppet` gem to be installed.  These tests
have initially be tested with the following integration of components in
addition to this module.  Modules such as
[stdlib](https://github.com/puppetlabs/puppetlabs-stdlib) may be checked out
into the same parent directory as this module.  The spec tests will
automatically add this parent directory to the Puppet module search path.

 * rspec 2.6
 * rspec-puppet 0.1.0
 * puppet 2.7.6
 * facter 1.6.3
 * stdlib 2.2.0

## Installing RSpec Testing Requirements

To install the testing requirements:

    % gem install rspec-puppet --no-ri --no-rdoc
    Successfully installed rspec-core-2.7.1
    Successfully installed diff-lcs-1.1.3
    Successfully installed rspec-expectations-2.7.0
    Successfully installed rspec-mocks-2.7.0
    Successfully installed rspec-2.7.0
    Successfully installed rspec-puppet-0.1.0
    6 gems installed

## Adding Tests

Please see the [rspec-puppet](https://github.com/rodjek/rspec-puppet) project
for information on writing tests.  A basic test that validates the class is
declared in the catalog is provided in the file `spec/classes/*_spec.rb`.
`rspec-puppet` automatically uses the top level description as the name of a
module to include in the catalog.  Resources may be validated in the catalog
using:

 * `contain_class('myclass')`
 * `contain_service('sshd')`
 * `contain_file('/etc/puppet')`
 * `contain_package('puppet')`
 * And so forth for other Puppet resources.

EOF
