json.users @users do |user|
  json.partial! 'shared/user', user: user, include_roles: true, include_stats: true
end

json.pagination do
  json.limit @limit
  json.offset @offset
  json.total @total
end
