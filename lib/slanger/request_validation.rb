module Slanger
  class RequestValidation < Struct.new :raw_body, :raw_params
    def socket_id
      return validate_socket_id!(data["socket_id"]) if data["socket_id"]
      return validate_socket_id!(params["socket_id"]) if params["socket_id"]
    end

    def params
      @params ||= validate_raw_params!
    end

    def data
      @data ||= JSON.parse(raw_body.tap{ |s| s.force_encoding('utf-8')})
    end

    private

    def validate_raw_params!
      restricted =  user_params.slice "body_md5", "auth_version", "auth_key", "auth_timestamp", "auth_signature", "app_id"

      invalid_keys = restricted.keys - user_params.keys

      if invalid_keys.any?
        raise Signature::AuthenticationError.new "Invalid params: #{invalid_keys}"
      end

      restricted
    end

    def user_params
      raw_params.reject{|k,_| %w(splat captures).include?(k)}
    end

    def validate_socket_id!(socket_id)
      unless valid_socket_id?(socket_id)
        raise Signature::AuthenticationError.new("Invalid socket_id: #{socket_id}")
      end

      socket_id
    end

    def valid_socket_id?(socket_id)
      socket_id =~ /\A[\da-fA-F]{8}\-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{12}\z/
    end
  end
end
