module Groupable
  class JoinsController < ApplicationController
    # GET /groupable/join?code=xxx
    def show
      invite = Invite.where_active_invite(join_params[:code]).first
      @group = invite&.group

      raise ActiveRecord::RecordNotFound, "Invalid invitation" unless @group

      render json: @group
    end

    # POST /groupable/join
    def create
      invite = Invite.where_active_invite(join_params[:code]).first
      group = invite&.group

      raise ActiveRecord::RecordNotFound, "Invalid invitation" unless group

      if group.joined?(current_user)
        return head :no_content
      end

      group.join!(current_user)

      render json: { status: "ok" }
    end

    private

    def join_params
      params.permit(:code)
    end
  end
end
