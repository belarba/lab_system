json.message "Login successful"
json.user do
  json.id @user.id
  json.email @user.email
  json.name @user.name
  json.roles @user.roles.pluck(:name)
end
json.access_token @tokens[:access_token]
json.refresh_token @tokens[:refresh_token]
json.expires_in @tokens[:expires_in]
