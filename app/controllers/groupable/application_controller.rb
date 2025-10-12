module Groupable
  class ApplicationController < ActionController::API
    # Host application must define current_user method
    # This can be done by including a concern or defining directly
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

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
