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
      # Routes defined as member routes use :id param instead of :group_id
      group_id = params[:group_id] || params[:id]
      @group = current_user.groupable_groups.find(group_id)
    end
  end
end
