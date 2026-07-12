module Groupable
  class MembersController < ApplicationController
    before_action :set_group
    before_action :require_editor_or_admin, only: [ :update, :destroy ]

    # GET /groupable/groups/:group_id/members
    def index
      @members = @group.groupable_members.includes(:user).order(:id)
      render json: @members
    end

    # GET /groupable/groups/:group_id/members/:user_id
    def show
      @member = @group.groupable_members.find_by!(user_id: params[:user_id])
      render json: @member
    end

    # PUT /groupable/groups/:group_id/members/:user_id
    def update
      member = @group.groupable_members.find_by!(user_id: params[:user_id])
      role = update_params[:role]

      unless role.present? && member_class.roles.key?(role.to_s)
        return render_bad_request("Invalid role: #{role}")
      end

      request_role = role.to_sym

      # Admin's role cannot be changed directly; promote another member instead
      return render_forbidden if member.admin?
      # Only an admin can promote another member to admin
      return render_forbidden if request_role == :admin && !current_member.admin?

      member_class.transaction do
        member.update!(role: request_role)

        # A group has a single admin: promoting a new admin demotes the current one
        if request_role == :admin && current_member.admin?
          current_member.update!(role: :editor)
        end
      end

      render json: { status: "ok" }
    end

    # DELETE /groupable/groups/:group_id/members/:user_id
    def destroy
      member = @group.groupable_members.find_by!(user_id: params[:user_id])

      # Admin member cannot be removed from the group
      return render_forbidden if member.admin?

      if member.destroy
        render json: { status: "ok" }
      else
        render json: { status: "error", error: member.errors }, status: :bad_request
      end
    end

    private

    def set_group
      @group = find_current_user_group(params[:group_id])
    end

    def update_params
      params.require(:item).permit(:role)
    end
  end
end
