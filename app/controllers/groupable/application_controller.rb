module Groupable
  class ApplicationController < Groupable.configuration.parent_controller_class
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def current_user
      return @current_user if defined?(@current_user)

      resolver = Groupable.configuration.current_user_resolver
      @current_user = if resolver
        resolver.call(self)
      elsif defined?(super)
        super
      end
    end

    private

    def render_not_found
      render json: { error: "Not found" }, status: :not_found
    end

    def render_unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def render_forbidden
      render json: { error: "Forbidden" }, status: :forbidden
    end

    def render_bad_request(message)
      render json: { error: message }, status: :bad_request
    end
  end
end
