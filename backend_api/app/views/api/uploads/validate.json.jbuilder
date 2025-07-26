json.validation_result do
  json.valid @valid
  json.filename @filename

  if @analysis
    json.analysis do
      json.file_hash @analysis[:file_hash]
      json.encoding @analysis[:encoding]
      json.delimiter @analysis[:delimiter]
      json.line_count @analysis[:line_count]
      json.headers @analysis[:headers]
      json.data_types @analysis[:data_types]
      json.validation_errors @analysis[:validation_errors]
      json.recommendations @analysis[:recommendations]

      json.sample_data @analysis[:sample_data] do |row|
        json.array! row
      end
    end
  end

  if @error
    json.error @error
  end
end

# app/views/api/uploads/analysis.json.jbuilder
json.upload_analysis @analysis

# app/views/api/uploads/stats.json.jbuilder
json.statistics @stats
json.generated_at Time.current
json.user do
  json.id current_user.id
  json.name current_user.name
  json.is_admin current_user.admin?
end
