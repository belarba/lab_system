json.message 'Patient is already associated with this doctor'
json.patient do
  json.partial! 'shared/user', user: @patient
end
