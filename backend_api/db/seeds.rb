# Limpar dados existentes (em ordem para evitar problemas de foreign key)
puts "Limpando dados existentes..."

ExamResult.destroy_all
ExamRequest.destroy_all
ExamType.destroy_all
RefreshToken.destroy_all
UserRole.destroy_all
Role.destroy_all
User.destroy_all

puts "Dados limpos!"

# Criar roles padrão
puts "Criando roles..."

# Criar roles padrão
roles = ["patient", "doctor", "lab_technician", "admin"]

roles.each do |role_name|
  Role.find_or_create_by(name: role_name) do |role|
    role.description = "#{role_name.humanize} role"
  end
end

puts "Created #{Role.count} roles"


# Criar tipos de exames
exam_types = [
  { name: "Cholesterol", unit: "mg/dL", reference_range: "< 200 mg/dL" },
  { name: "Triglycerides", unit: "mg/dL", reference_range: "< 150 mg/dL" },
  { name: "Glucose", unit: "mg/dL", reference_range: "70-99 mg/dL" },
  { name: "Hemoglobin", unit: "g/dL", reference_range: "13-17 g/dL" }
]

exam_types.each do |exam_data|
  ExamType.find_or_create_by(name: exam_data[:name]) do |exam_type|
    exam_type.unit = exam_data[:unit]
    exam_type.reference_range = exam_data[:reference_range]
  end
end

puts "Created #{ExamType.count} exam types"


# Criar usuários
puts "Criando usuários..."

users_data = [
  {
    email: "josephmartin@aquaporservicos.pt",
    name: "Joseph Martin",
    password: "password123",
    roles: ["doctor", "patient"]
  },
  {
    email: "mariorodas@lusagua.pt",
    name: "Mário Rodas",
    password: "password123",
    roles: ["lab_technician"]
  },
  {
    email: "anasilva@health.pt",
    name: "Ana Silva",
    password: "password123",
    roles: ["patient"]
  },
  {
    email: "luicosta@clinic.pt",
    name: "Luis Costa",
    password: "password123",
    roles: ["doctor"]
  }
]

users_data.each do |user_data|
  user = User.create!(
    email: user_data[:email],
    name: user_data[:name],
    password: user_data[:password],
    password_confirmation: user_data[:password]
  )

  # Atribuir roles
  user_data[:roles].each do |role_name|
    role = Role.find_by(name: role_name)
    user.roles << role if role
  end

  puts "Criado usuário: #{user.name} (#{user_data[:roles].join(", ")})"
end


# Criar exames agendados
puts "Criando exames agendados..."

# Buscar usuários e tipos de exames
ana = User.find_by(email: "anasilva@health.pt")
joseph = User.find_by(email: "josephmartin@aquaporservicos.pt")
luis = User.find_by(email: "luicosta@clinic.pt")

glucose = ExamType.find_by(name: "Glucose")
cholesterol = ExamType.find_by(name: "Cholesterol")
hemoglobin = ExamType.find_by(name: "Hemoglobin")

exam_requests = [
  {
    patient: ana,
    doctor: luis,
    exam_type: glucose,
    scheduled_date: "2025-04-23T08:00:00Z",
    status: "scheduled"
  },
  {
    patient: ana,
    doctor: luis,
    exam_type: cholesterol,
    scheduled_date: "2025-04-24T09:00:00Z",
    status: "scheduled"
  },
  {
    patient: joseph,
    doctor: luis,
    exam_type: hemoglobin,
    scheduled_date: "2025-04-25T10:00:00Z",
    status: "scheduled"
  }
]

exam_requests.each do |request_data|
  ExamRequest.create!(
    patient: request_data[:patient],
    doctor: request_data[:doctor],
    exam_type: request_data[:exam_type],
    scheduled_date: request_data[:scheduled_date],
    status: request_data[:status],
    notes: "Exame agendado via seed"
  )

  puts "Criado exame: #{request_data[:patient].name} - #{request_data[:exam_type].name} - #{request_data[:scheduled_date]}"
end

puts "Criados #{ExamRequest.count} exames agendados"

puts "Seed concluído com sucesso!"
