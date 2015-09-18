#
# create_ceph_config.rb
#

module Puppet::Parser::Functions
  newfunction(:create_ceph_config, :type => :statement, :doc => <<-EOS
Uses create_resources to create a set of ceph_config resources from a hash:
    $settings = { 
        section1/setting2 => val2,
        section2/setting3 => {
          ensure => absent
        }
      }
    }
    $defaults = {
      path => '/tmp/foo.ini'
    }
    create_ceph_config($settings,$defaults)
Will create the following resources
    ceph_config{'/tmp/foo.ini [section1] setting2':
      ensure  => present,
      value   => 'val2',
      path    => '/tmp/foo.ini',
    }
    ceph_config{'/tmp/foo.ini [section2] setting3':
      ensure  => absent,
      path    => '/tmp/foo.ini',
    }
EOS
  ) do |arguments|

    raise(Puppet::ParseError, "create_ceph_config(): Wrong number of arguments " +
      "given (#{arguments.size} for 1 or 2)") unless arguments.size.between?(1,2)

    settings = arguments[0]
    defaults = arguments[1] || {}

    if [settings,defaults].any?{|i| !i.is_a?(Hash) }
      raise(Puppet::ParseError,
        'create_ceph_config(): Requires all arguments to be a Hash')
    end

    resources = settings.keys.inject({}) do |res, section|
      unless path = defaults.merge(settings)['path']
        raise Puppet::ParseError, 'create_ceph_config(): must pass the path parameter to the Ini_setting resource!'
      end

      settings.each do |setting, value|
        if value
          res["#{path} #{setting}"] = {
            'ensure'  => 'present',
            'value' => value,
          }
        end
      end
      res
    end

    Puppet::Parser::Functions.function('create_resources')
    function_create_resources(['ceph_config',resources,defaults])
  end
end