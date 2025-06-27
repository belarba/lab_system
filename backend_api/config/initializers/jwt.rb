JWT_SECRET = Rails.application.credentials.secret_key_base || "your-secret-key"
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRATION = 15.minutes
REFRESH_TOKEN_EXPIRATION = 7.days
