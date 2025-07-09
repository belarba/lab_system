json.message 'User created successfully'
json.user do
  json.partial! 'shared/user', user: @user, include_roles: true, include_stats: true
end
