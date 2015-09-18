#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
#   Copyright (C) 2014 Nine Internet Solutions AG
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
#
# == Class: ceph
#
# init takes care of installing/configuring the common dependencies across classes
# it also takes care of the global configuration values
#
# === Parameters:
#
# [*fsid*] The cluster's fsid.
#   Mandatory. Get one with `uuidgen -r`.
#
# [*ensure*] Installs ( present ) or removes ( absent ) ceph.
#   Optional. Defaults to present.
#
# [*authentication_type*] Authentication type.
#   Optional. none or 'cephx'. Defaults to 'cephx'.
#
# [*keyring*] The location of the keyring retrieved by default
#   Optional. Defaults to /etc/ceph/keyring.
#
# [*osd_journal_size*] The size of the journal file/device.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_pg_num*] The default number of PGs per pool.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_pgp_num*] The default flags for new pools.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_size*] Number of replicas for objects in the pool
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_min_size*] The default minimum num of replicas.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_crush_rule*] The default CRUSH ruleset to use
#   when creating a pool.
#   Optional. Integer. Default provided by Ceph.
#
# [*mon_osd_full_ratio*] Percentage of disk space used before
#   an OSD considered full
#   Optional. Integer e.g. 95, NOTE: ends in config as .95
#   Default provided by Ceph.
#
# [*mon_osd_nearfull_ratio*] Percentage of disk space used before
#   an OSD considered nearfull
#   Optional. Float e.g. 90, NOTE: ends in config as .90
#   Default provided by Ceph.
#
# [*mon_initial_members*] The IDs of initial MONs in the cluster during startup.
#   Optional. String like e.g. 'a, b, c'.
#
# [*mon_host*] The fqdn of MONs in the cluster. They can also be declared
#   individually through ceph::mon.
#   Optional. String like e.g. 'a, b, c'.
#
# [*require_signatures*] If Ceph requires signatures on all
#   message traffic (client<->cluster and between cluster daemons).
#   Optional. Boolean. Default provided by Ceph.
#
# [*cluster_require_signatures*] If Ceph requires signatures on all
#   message traffic between the cluster daemons.
#   Optional. Boolean. Default provided by Ceph.
#
# [*service_require_signatures*] If Ceph requires signatures on all
#   message traffic between clients and the cluster.
#   Optional. Boolean. Default provided by Ceph.
#
# [*sign_messages*] If all ceph messages should be signed.
#   Optional. Boolean. Default provided by Ceph.
#
# [*cluster_network*] The address of the cluster network.
#   Optional. {cluster-network-ip/netmask}
#
# [*public_network*] The address of the public network.
#   Optional. {public-network-ip/netmask}
#
# [*cluster*] Which cluster to use.
#   Optional. Default is ceph.
#
class ceph (
  $fsid,
  $ensure                     = present,
  $authentication_type        = 'cephx',
  $keyring                    = undef,
  $osd_journal_size           = undef,
  $osd_pool_default_pg_num    = undef,
  $osd_pool_default_pgp_num   = undef,
  $osd_pool_default_size      = undef,
  $osd_pool_default_min_size  = undef,
  $osd_pool_default_crush_rule= undef,
  $mon_osd_full_ratio         = undef,
  $mon_osd_nearfull_ratio     = undef,
  $mon_initial_members        = undef,
  $mon_host                   = undef,
  $require_signatures         = undef,
  $cluster_require_signatures = undef,
  $service_require_signatures = undef,
  $sign_messages              = undef,
  $cluster_network            = undef,
  $public_network             = undef,
  $cluster                    ='ceph'
) {
  include ::ceph::params

  package { $::ceph::params::packages :
    ensure => $ensure,
    tag    => 'ceph'
  }

  if $ensure !~ /(absent|purged)/ {
    $defaults = { 'path' => "/etc/ceph/${cluster}.conf" }

    # Make sure ceph is installed before managing the configuration
    Package<| tag == 'ceph' |> -> Ceph_Config<| |>
    # [global]
    $ceph_global_config = {
      'global/fsid'                         => $fsid, 
      'global/keyring'                      => $keyring, 
      'global/osd_pool_default_pg_num'      => $osd_pool_default_pg_num, 
      'global/osd_pool_default_pgp_num'     => $osd_pool_default_pgp_num, 
      'global/osd_pool_default_size'        => $osd_pool_default_size,
      'global/osd_pool_default_min_size'    => $osd_pool_default_min_size,
      'global/osd_pool_default_crush_rule'  => $osd_pool_default_crush_rule,
      'global/mon_osd_full_ratio'           => $mon_osd_full_ratio,
      'global/mon_osd_nearfull_ratio'       => $mon_osd_nearfull_ratio,
      'global/mon_initial_members'          => $mon_initial_members,
      'global/mon_host'                     => $mon_host,
      'global/require_signatures'           => $require_signatures,
      'global/cluster_require_signatures'   => $cluster_require_signatures,
      'global/service_require_signatures'   => $service_require_signatures,
      'global/sign_messages'                => $sign_messages,
      'global/cluster_network'              => $cluster_network,
      'global/public_network'               => $public_network,
      'osd/osd_journal_size'                => $osd_journal_size,
    }
    create_ceph_config($ceph_global_config, $defaults)

    if $authentication_type == 'cephx' {
      $ceph_auth_config = {
        'global/auth_cluster_required'  => 'cephx',
        'global/auth_service_required'  => 'cephx',
        'global/auth_client_required'   => 'cephx',
        'global/auth_supported'         => 'cephx',
      }
      create_ceph_config($ceph_auth_config, $defaults)
    } else {
      $ceph_auth_config = {
        'global/auth_cluster_required'  => 'none',
        'global/auth_service_required'  => 'none',
        'global/auth_client_required'   => 'none',
        'global/auth_supported'         => 'none',
      }
      create_ceph_config($ceph_auth_config, $defaults)
    }
  }
}
