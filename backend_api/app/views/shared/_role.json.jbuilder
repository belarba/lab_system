json.id role.id
json.name role.name
json.description role.description

# Incluir contagem de usuários se solicitado
if local_assigns[:include_user_count]
  json.user_count role.users.count
end
