# = Class: pe_devel
#
# This module manages common developer resources on PE supported platforms.
# Initially it will be designed for Enterprise Linux 6 variants, but additional
# platforms should be easy to add to the module.
#
# = Parameters
#
# [*epel_release_url*]
#   This parameter, if not provided will default to
#   http://mirror.cogentco.com/pub/linux/epel/6/i386/epel-release-6-5.noarch.rpm
#   The same parameter may also be set at as a node parameter in the event the
#   Puppet Console is being used to set parameters.
#
# [*puppetenterprise_baseurl*]
#   This parameter is a URL to the base directory of an HTTP server providing
#   the Puppet Enteprise packages in a repository format suitable for the node
#   being managed by this module.  If left unspecified this parameter will
#   default to http://links.puppetlabs.com/puppet-enterprise/ which will redirect
#   accordingly.  NOTE, you can easily create your own repository using
#   createrepo inside of the packages/ subdirectory of the Puppet Enterprise
#   distribution tarball on YUM based platforms.
#
# = Actions
#
# The module aims to manage these resources on the PE system being developed
# on.
#
# * wget
# * curl
# * build-essential or equivalent
# * gcc
# * make
# * pe-ruby-devel
#
# = Requires
#
# The stdlib module.
#
# = Sample Usage
#
# puppet apply -v -e 'include pe_devel'
#
class pe_devel (
  $epel_release_url = 'UNSET',
  $puppetenterprise_baseurl = 'UNSET'
) {

  # Look up the epel release URL in the top scope if we don't have it here.
  $epel_release_url_real = $epel_release_url ? {
    UNSET => $::epel_release_url ? {
      undef   => "http://mirror.cogentco.com/pub/linux/epel/6/i386/epel-release-6-5.noarch.rpm",
      default => $::epel_release_url,
    },
    default => $epel_release_url,
  }
  # Validate the URL is a HTTP URL
  validate_re($epel_release_url_real, '^https?://')

  # Look up the PE repository URL.
  $puppetenterprise_baseurl_real = $puppetenterprise_baseurl ? {
    UNSET => $::puppetenterprise_baseurl ? {
      undef   => "http://links.puppetlabs.com/puppet-enterprise",
      default => $::puppetenterprise_baseurl,
    },
    default => $puppetenterprise_baseurl,
  }
  validate_re($puppetenterprise_baseurl_real, '^https?://')

  # The Anchor Pattern is to work around Puppet issue 8040
  # More information at: http://links.puppetlabs.com/anchor_pattern
  anchor { "pe_devel::begin": }
  anchor { "pe_devel::end": }

  case $::osfamily {
    redhat: {
      class { 'pe_devel::redhat':
        require => Anchor['pe_devel::begin'],
        before  => Anchor['pe_devel::end'],
      }
    }
    default: {
      $msg = "OS Family: [${osfamily}] is not implemented"
      # Master side warning
      warning $msg
      # Agent side notification
      notify { "$module_name unimplemented": message => $msg }
    }
  }
}

class pe_devel::redhat {
  Package {
    ensure  => latest,
    require => [ Package['epel-release'], File['puppetenterprise.repo'] ],
  }
  File {
    owner => 0,
    group => 0,
    mode  => '0644',
  }

  # Look up the lsbmajdistrelease fact.
  if $::lsbmajdistrelease {
    # We can't install this package until the lsbmajdistrelease fact becomes available.
    package { 'pe-ruby-devel': }
  } else {
    notify { "lsbmajdistrelease unavailable":
      message => "The lsbmajdistrelease fact is not avilable during this catalog compilation.  The catalog contains the Package[redhat-lsb] resource to make the lsbmajdistrelease fact available on the next run.  Please run Puppet again to manage the pe-ruby-devel package and fill in the puppetenterprise.repo template."
    }
  }

  # This selector prevents an ERB exception trying to look up a potentially missing
  # fact.  The fact may be missing if the redhat-lsb package is not installed.
  $puppetenterprise_repo_content = $::lsbmajdistrelease ? {
    undef   => "# Contents not yet available.  Please run Puppet again.\n",
    default => template("${module_name}/puppetenterprise.repo.erb"),
  }

  # JJM: REVISIT, We'll need this to support different PE versions automatically
  # which means we'll need a PE major version facter fact in stdlib.
  # Setup a repository source for Puppet Enterprise
  file { 'puppetenterprise.repo':
    path    => '/etc/yum.repos.d/puppetenterprise.repo',
    content => $puppetenterprise_repo_content,
  }
  # This package gives us the $lsbmajdistrelease fact on the second run if it
  # is not already available.
  package { 'redhat-lsb': }

  # The EPEL package is special because other packages can't be installed
  # without it being present first.  We assign undef to the require parameter
  # to avoid the resource default causing a dependency cycle in the graph.
  package { epel-release:
    ensure   => present,
    provider => rpm,
    source   => $pe_devel::epel_release_url_real,
    require  => undef,
  }
  package { curl: }
  package { wget: }
  package { gcc: }
  package { make: }
  package { 'glibc-devel': }
  package { createrepo: }
}
# EOF
