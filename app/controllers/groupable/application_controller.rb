module Groupable
  class ApplicationController < Groupable.configuration.parent_controller_class
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

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

    def group_class
      Groupable.configuration.group_class
    end

    def member_class
      Groupable.configuration.member_class
    end

    def invite_class
      Groupable.configuration.invite_class
    end

    # Find an active group the current user belongs to
    def find_current_user_group(id)
      current_user.groupable_groups.where(active: true).find(id)
    end

    # Member record of current_user in @group (must be set by set_group)
    def current_member
      @current_member ||= @group.member_of_user(current_user)
    end

    def require_editor_or_admin
      render_forbidden unless current_member && (current_member.editor? || current_member.admin?)
    end

    def ensure_invites_enabled
      render_not_found unless Groupable.configuration.enable_invites
    end

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

    def render_record_invalid(exception)
      render json: { error: exception.record.errors.full_messages.join(", ") },
             status: :unprocessable_entity
    end

    def render_parameter_missing(exception)
      render_bad_request(exception.message)
    end
  end
end
