module ApiHelpers
  def json_response
    return {} if response.body.empty?

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      # Se não conseguir parsear JSON, retorna um hash vazio
      # Isso pode acontecer quando o Rails retorna uma página de erro HTML
      {}
    end
  end

  def auth_headers(user)
    tokens = user.generate_tokens
    { 'Authorization' => "Bearer #{tokens[:access_token]}" }
  end

  def auth_headers_with_invalid_token
    { 'Authorization' => 'Bearer invalid_token' }
  end

  def debug_response
    puts "Response status: #{response.status}"
    puts "Response body: #{response.body}"
    puts "Response headers: #{response.headers}"
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
