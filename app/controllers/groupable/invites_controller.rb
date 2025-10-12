module Groupable
  class InvitesController < ApplicationController
    before_action :set_group

    # POST /groupable/groups/:group_id/invites
    def create
      @invite = @group.invites.create!

      render json: { code: @invite.code }
    end

    private

    def set_group
      @group = current_user.groupable_groups.find(params[:group_id])
    end
  end
end
