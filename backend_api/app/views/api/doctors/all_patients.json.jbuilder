json.patients @patients do |patient|
  json.partial! 'shared/user', user: patient
end

json.pagination do
  json.limit @limit
  json.offset @offset
  json.total @total
end
