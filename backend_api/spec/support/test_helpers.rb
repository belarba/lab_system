module TestHelpers
  def json_response
    return {} if response.body.empty?
    JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end

  def auth_headers(user)
    tokens = user.generate_tokens
    { 'Authorization' => "Bearer #{tokens[:access_token]}" }
  end

  # Helper para criar arquivo CSV para testes
  def create_csv_file(content, filename = 'test.csv')
    file = Tempfile.new([filename.gsub('.csv', ''), '.csv'])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: filename)
  end

  # Helper para setup básico de roles
  def setup_roles
    Role.find_or_create_by(name: 'patient', description: 'Patient role')
    Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
    Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role')
    Role.find_or_create_by(name: 'admin', description: 'Admin role')
  end
end

RSpec.configure do |config|
  config.include TestHelpers, type: :request
  config.include TestHelpers, type: :integration
  config.include TestHelpers, type: :model

  # Setup roles before each test
  config.before(:each) do
    Role.find_or_create_by(name: 'patient', description: 'Patient role')
    Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
    Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role')
    Role.find_or_create_by(name: 'admin', description: 'Admin role')
  end
end
