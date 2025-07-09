json.user do
  json.partial! 'shared/user', user: current_user, include_roles: true
end
