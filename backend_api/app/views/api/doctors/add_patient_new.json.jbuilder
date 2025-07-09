json.message 'Patient can now receive exam requests from this doctor'
json.patient do
  json.partial! 'shared/user', user: @patient
end
