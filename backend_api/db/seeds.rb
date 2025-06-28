# Limpar dados existentes (em ordem para evitar problemas de foreign key)
puts "Limpando dados existentes..."

ExamResult.destroy_all
ExamRequest.destroy_all
ExamType.destroy_all
RefreshToken.destroy_all
LabFileUpload.destroy_all
UserRole.destroy_all
Role.destroy_all
User.destroy_all

puts "Dados limpos!"

# Criar roles padrão
puts "Criando roles..."

roles = ["patient", "doctor", "lab_technician", "admin"]

roles.each do |role_name|
  Role.find_or_create_by(name: role_name) do |role|
    role.description = "#{role_name.humanize} role"
  end
end

puts "Created #{Role.count} roles"

# Criar tipos de exames
exam_types = [
  {
    name: "Cholesterol",
    unit: "mg/dL",
    reference_range: "< 200 mg/dL",
    description: "Total cholesterol measurement"
  },
  {
    name: "Triglycerides",
    unit: "mg/dL",
    reference_range: "< 150 mg/dL",
    description: "Triglycerides level measurement"
  },
  {
    name: "Glucose",
    unit: "mg/dL",
    reference_range: "70-99 mg/dL",
    description: "Fasting blood glucose level"
  },
  {
    name: "Hemoglobin",
    unit: "g/dL",
    reference_range: "13-17 g/dL",
    description: "Hemoglobin concentration in blood"
  }
]

exam_types.each do |exam_data|
  ExamType.find_or_create_by(name: exam_data[:name]) do |exam_type|
    exam_type.unit = exam_data[:unit]
    exam_type.reference_range = exam_data[:reference_range]
    exam_type.description = exam_data[:description]
  end
end

puts "Created #{ExamType.count} exam types"

# Criar usuários
puts "Criando usuários..."

users_data = [
  {
    email: "admin@labsystem.pt",
    name: "System Administrator",
    phone: "+351 91 123 4567",
    password: "admin123",
    roles: ["admin"]
  },
  {
    email: "josephmartin@aquaporservicos.pt",
    name: "Joseph Martin",
    phone: "+351 91 234 5678",
    password: "password123",
    roles: ["doctor", "patient"]
  },
  {
    email: "mariorodas@lusagua.pt",
    name: "Mário Rodas",
    phone: "+351 92 345 6789",
    password: "password123",
    roles: ["lab_technician"]
  },
  {
    email: "anasilva@health.pt",
    name: "Ana Silva",
    phone: "+351 93 456 7890",
    password: "password123",
    roles: ["patient"]
  },
  {
    email: "luiscosta@clinic.pt",
    name: "Luis Costa",
    phone: "+351 94 567 8901",
    password: "password123",
    roles: ["doctor"]
  },
  {
    email: "mariaferreira@health.pt",
    name: "Maria Ferreira",
    phone: "+351 95 678 9012",
    password: "password123",
    roles: ["patient"]
  },
  {
    email: "pedrosousa@clinic.pt",
    name: "Pedro Sousa",
    phone: "+351 96 789 0123",
    password: "password123",
    roles: ["doctor"]
  },
  {
    email: "catarina@lab.pt",
    name: "Catarina Santos",
    phone: "+351 97 890 1234",
    password: "password123",
    roles: ["lab_technician"]
  }
]

users_data.each do |user_data|
  user = User.create!(
    email: user_data[:email],
    name: user_data[:name],
    phone: user_data[:phone],
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

# Criar exames agendados e alguns resultados
puts "Criando exames agendados e resultados..."

# Buscar usuários e tipos de exames
ana = User.find_by(email: "anasilva@health.pt")
maria = User.find_by(email: "mariaferreira@health.pt")
joseph = User.find_by(email: "josephmartin@aquaporservicos.pt")
luis = User.find_by(email: "luiscosta@clinic.pt")
pedro = User.find_by(email: "pedrosousa@clinic.pt")
mario = User.find_by(email: "mariorodas@lusagua.pt")
catarina = User.find_by(email: "catarina@lab.pt")

glucose = ExamType.find_by(name: "Glucose")
cholesterol = ExamType.find_by(name: "Cholesterol")
hemoglobin = ExamType.find_by(name: "Hemoglobin")

exam_requests_data = [
  # Ana Silva - paciente com vários exames
  {
    patient: ana,
    doctor: luis,
    exam_type: glucose,
    scheduled_date: 2.weeks.ago,
    status: "completed"
  },
  {
    patient: ana,
    doctor: luis,
    exam_type: cholesterol,
    scheduled_date: 2.weeks.ago,
    status: "completed"
  },
  {
    patient: ana,
    doctor: luis,
    exam_type: glucose,
    scheduled_date: 3.days.from_now,
    status: "scheduled"
  },

  # Maria Ferreira
  {
    patient: maria,
    doctor: pedro,
    exam_type: hemoglobin,
    scheduled_date: 1.week.ago,
    status: "completed"
  },
  {
    patient: maria,
    doctor: pedro,
    exam_type: glucose,
    scheduled_date: 2.days.from_now,
    status: "scheduled"
  },

  # Joseph Martin (médico que também é paciente)
  {
    patient: joseph,
    doctor: pedro,
    exam_type: cholesterol,
    scheduled_date: 3.days.ago,
    status: "completed"
  }
]

exam_requests_data.each do |request_data|
  exam_request = ExamRequest.create!(
    patient: request_data[:patient],
    doctor: request_data[:doctor],
    exam_type: request_data[:exam_type],
    scheduled_date: request_data[:scheduled_date],
    status: request_data[:status],
    notes: "Exame #{request_data[:status] == 'completed' ? 'realizado' : 'agendado'} via seed"
  )

  # Se o status é completed, criar resultado
  if request_data[:status] == "completed"
    lab_tech = [mario, catarina].sample

    # Valores baseados no tipo de exame
    value = case request_data[:exam_type].name
            when "Glucose"
              rand(80..120)
            when "Cholesterol"
              rand(150..250)
            when "Hemoglobin"
              rand(12..16)
            else
              rand(50..200)
            end

    ExamResult.create!(
      exam_request: exam_request,
      value: value,
      unit: request_data[:exam_type].unit,
      lab_technician: lab_tech,
      performed_at: request_data[:scheduled_date] + rand(1..3).hours,
      notes: "Resultado processado automaticamente pelo sistema"
    )
  end

  puts "Criado exame: #{request_data[:patient].name} - #{request_data[:exam_type].name} - #{request_data[:status]}"
end

puts "Criados #{ExamRequest.count} exames agendados"
puts "Criados #{ExamResult.count} resultados de exames"

# Criar alguns uploads de exemplo
puts "Criando uploads de exemplo..."

upload1 = LabFileUpload.create!(
  filename: "lab_results_jan_2025.csv",
  file_size: 2048,
  uploaded_by: mario,
  status: 'completed',
  total_records: 15,
  processed_records: 15,
  failed_records: 0,
  processed_at: 1.week.ago,
  processing_summary: {
    success_rate: 100.0,
    details: [
      { timestamp: 1.week.ago.iso8601, message: "Processing started" },
      { timestamp: (1.week.ago + 5.minutes).iso8601, message: "Successfully processed 15 records" }
    ]
  }.to_json
)

upload2 = LabFileUpload.create!(
  filename: "lab_results_dec_2024.csv",
  file_size: 1536,
  uploaded_by: catarina,
  status: 'completed',
  total_records: 12,
  processed_records: 10,
  failed_records: 2,
  processed_at: 2.weeks.ago,
  processing_summary: {
    success_rate: 83.33,
    details: [
      { timestamp: 2.weeks.ago.iso8601, message: "Processing started" },
      { timestamp: (2.weeks.ago + 3.minutes).iso8601, message: "2 records failed validation" },
      { timestamp: (2.weeks.ago + 8.minutes).iso8601, message: "Processing completed with errors" }
    ]
  }.to_json
)

puts "Criados #{LabFileUpload.count} uploads de exemplo"

puts "\n=== SEED CONCLUÍDO COM SUCESSO! ==="
puts "\nResumo dos dados criados:"
puts "- #{User.count} usuários"
puts "- #{Role.count} roles"
puts "- #{ExamType.count} tipos de exame"
puts "- #{ExamRequest.count} requisições de exame"
puts "- #{ExamResult.count} resultados de exame"
puts "- #{LabFileUpload.count} uploads de laboratório"

puts "\nUsuários criados:"
User.includes(:roles).each do |user|
  roles = user.roles.pluck(:name).join(", ")
  puts "- #{user.name} (#{user.email}) - Roles: #{roles}"
end

puts "\nCredenciais de login:"
puts "Admin: admin@labsystem.pt / admin123"
puts "Médico: luiscosta@clinic.pt / password123"
puts "Paciente: anasilva@health.pt / password123"
puts "Lab Tech: mariorodas@lusagua.pt / password123"
