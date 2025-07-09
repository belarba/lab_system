json.roles @roles do |role|
  json.partial! 'shared/role', role: role
end
