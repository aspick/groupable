module Groupable
  class ApplicationController < ActionController::API
    # Host application must define current_user method
    # This can be done by including a concern or defining directly
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    # For testing: delegate current_user to main ApplicationController if available
    def current_user
      return @current_user if defined?(@current_user)

      # In test environment, try to use test header
      # Rails converts X-Test-User-Id to HTTP_X_TEST_USER_ID
      if Rails.env.test?
        user_id = request.headers['HTTP_X_TEST_USER_ID'] || request.headers['X-Test-User-Id']
        if user_id.present?
          user_class = Groupable.configuration.user_class
          @current_user = user_class.find_by(id: user_id)
        end
      end

      @current_user
    end

    private

    def render_not_found
      render json: { error: 'Not found' }, status: :not_found
    end

    def render_unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def render_forbidden
      render json: { error: 'Forbidden' }, status: :forbidden
    end

    def render_bad_request(message)
      render json: { error: message }, status: :bad_request
    end
  end
end
