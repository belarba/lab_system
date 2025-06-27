class JwtService
  class << self
    def encode_access_token(user_id)
      payload = {
        user_id: user_id,
        exp: ACCESS_TOKEN_EXPIRATION.from_now.to_i,
        type: "access"
      }
      JWT.encode(payload, JWT_SECRET, JWT_ALGORITHM)
    end

    def encode_refresh_token(user_id)
      payload = {
        user_id: user_id,
        exp: REFRESH_TOKEN_EXPIRATION.from_now.to_i,
        type: "refresh",
        jti: SecureRandom.uuid
      }
      JWT.encode(payload, JWT_SECRET, JWT_ALGORITHM)
    end

    def decode_token(token)
      decoded = JWT.decode(token, JWT_SECRET, true, algorithm: JWT_ALGORITHM)[0]
      decoded.with_indifferent_access
    rescue JWT::DecodeError => e
      nil
    end

    def token_expired?(token)
      decoded = decode_token(token)
      return true unless decoded

      Time.current.to_i > decoded[:exp]
    end
  end
end
