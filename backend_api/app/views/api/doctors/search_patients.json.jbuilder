json.patients @patients do |patient|
  json.partial! 'shared/user', user: patient
end
