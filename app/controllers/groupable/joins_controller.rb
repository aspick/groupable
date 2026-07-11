module Groupable
  class JoinsController < ApplicationController
    before_action :ensure_invites_enabled

    # GET /groupable/join?code=xxx
    def show
      render json: find_group_by_code!
    end

    # POST /groupable/join
    def create
      group = find_group_by_code!

      if group.joined?(current_user)
        return head :no_content
      end

      group.join!(current_user)

      render json: { status: "ok" }
    end

    private

    def find_group_by_code!
      invite = invite_class.where_active_invite(join_params[:code]).first
      group = invite&.group

      raise ActiveRecord::RecordNotFound, "Invalid invitation" unless group&.active?

      group
    end

    def join_params
      params.permit(:code)
    end
  end
end
