json.message 'CSV data generated successfully'
json.csv_data @csv_data
json.results_count @results.count
json.patient do
  json.id @patient.id
  json.name @patient.name
  json.email @patient.email
end
