module Groupable
  class InvitesController < ApplicationController
    before_action :ensure_invites_enabled
    before_action :set_group
    before_action :require_editor_or_admin

    # POST /groupable/groups/:group_id/invites
    def create
      @invite = @group.groupable_invites.create!

      render json: { code: @invite.code }
    end

    private

    def set_group
      @group = find_current_user_group(params[:group_id])
    end
  end
end
