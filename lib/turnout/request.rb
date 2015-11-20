require 'ipaddr'

module Turnout
  class Request
    def initialize(env)
      @rack_request = Rack::Request.new(env)
    end

    def allowed?(settings)
      path_allowed?(settings.allowed_paths) ||
      ip_allowed?(settings.allowed_ips) ||
      user_allowed?(settings.allowed_users)
    end

    private

    attr_reader :rack_request

    def path_allowed?(allowed_paths)
      allowed_paths.any? do |allowed_path|
        rack_request.path =~ Regexp.new(allowed_path)
      end
    end

    def ip_allowed?(allowed_ips)
      begin
        ip = IPAddr.new(rack_request.ip.to_s)
      rescue ArgumentError
        return false
      end

      allowed_ips.any? do |allowed_ip|
        IPAddr.new(allowed_ip).include? ip
      end
    end

    def user_allowed?(allowed_users)
      warden = rack_request.env['warden']
      return false unless warden

      user = warden.user
      return false unless user

      allowed_users.any? do |allowed_user|
        allowed_user == user.id
      end
    end
  end
end