require 'rails_helper'

RSpec.describe 'Api::Auth', type: :request do
  describe 'POST /api/auth/login' do
    let(:user) { create(:user, :doctor) }
    let(:valid_params) do
      {
        email: user.email,
        password: 'password123'
      }
    end

    context 'with valid credentials' do
      it 'returns access and refresh tokens' do
        post '/api/auth/login', params: valid_params

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'message' => 'Login successful'
        )
        expect(json_response).to have_key('access_token')
        expect(json_response).to have_key('refresh_token')
        expect(json_response).to have_key('expires_in')
        expect(json_response).to have_key('user')

        expect(json_response['user']).to include(
          'id' => user.id,
          'email' => user.email,
          'roles' => ['doctor']
        )
      end

      it 'creates refresh token in database' do
        expect {
          post '/api/auth/login', params: valid_params
        }.to change(RefreshToken, :count).by(1)
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized with wrong password' do
        post '/api/auth/login', params: { email: user.email, password: 'wrong' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'returns unauthorized with wrong email' do
        post '/api/auth/login', params: { email: 'wrong@email.com', password: 'password123' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid credentials')
      end
    end
  end

  describe 'POST /api/auth/refresh' do
    let(:user) { create(:user, :patient) }
    let(:tokens) { user.generate_tokens }

    context 'with valid refresh token' do
      it 'returns new tokens' do
        post '/api/auth/refresh', params: { refresh_token: tokens[:refresh_token] }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'message' => 'Token refreshed'
        )
        expect(json_response).to have_key('access_token')
        expect(json_response).to have_key('refresh_token')
      end

      it 'invalidates old refresh token' do
        old_token = tokens[:refresh_token]
        post '/api/auth/refresh', params: { refresh_token: old_token }

        expect(RefreshToken.find_by(token: old_token)).to be_nil
      end
    end

    context 'with invalid refresh token' do
      it 'returns unauthorized' do
        post '/api/auth/refresh', params: { refresh_token: 'invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid refresh token')
      end
    end
  end

  describe 'POST /api/auth/logout' do
    let(:user) { create(:user, :admin) }
    let(:tokens) { user.generate_tokens }

    it 'returns unauthorized without token' do
      post '/api/auth/logout', params: { refresh_token: tokens[:refresh_token] }
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Unauthorized')
    end

    it 'returns unauthorized with invalid token' do
      post '/api/auth/logout',
           params: { refresh_token: tokens[:refresh_token] },
           headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Unauthorized')
    end

    context 'when authenticated' do
      it 'destroys refresh token' do
        post '/api/auth/logout',
             params: { refresh_token: tokens[:refresh_token] },
             headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Logged out successfully')
        expect(RefreshToken.find_by(token: tokens[:refresh_token])).to be_nil
      end
    end
  end
end
