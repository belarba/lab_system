json.message 'CSV data generated successfully'
json.csv_data @csv_data
json.results_count @results.count
json.doctor do
  json.partial! 'shared/user', user: @doctor, include_roles: true
end
