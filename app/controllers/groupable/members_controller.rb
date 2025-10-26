module Groupable
  class MembersController < ApplicationController
    before_action :set_group
    before_action :require_editor_or_admin, only: [ :update, :destroy ]

    # GET /groupable/groups/:group_id/members
    def index
      @members = @group.members.includes(:user).order(:id)
      render json: @members
    end

    # GET /groupable/groups/:group_id/members/:id
    def show
      @member = @group.members.find_by!(user_id: params[:id])
      render json: @member
    end

    # PUT /groupable/groups/:group_id/members/:id
    def update
      member = @group.members.find_by!(user_id: params[:id])
      request_role = update_params[:role].to_sym

      check_update_permission!(member, request_role)

      Member.transaction do
        member.update!(role: request_role)

        # If upgrading to admin, downgrade current user to editor
        if request_role == :admin
          current_member = @group.member_of_user(current_user)
          current_member.update!(role: :editor) if current_member.admin?
        end
      end

      render json: { status: "ok" }
    end

    # DELETE /groupable/groups/:group_id/members/:id
    def destroy
      member = @group.members.find_by!(user_id: params[:id])

      check_delete_permission!(member)

      if member.destroy
        render json: { status: "ok" }
      else
        render json: { status: "error", error: member.errors }, status: :bad_request
      end
    end

    private

    def set_group
      @group = current_user.groupable_groups.find(params[:group_id])
    end

    def update_params
      params.require(:item).permit(:role)
    end

    def require_editor_or_admin
      current_member = @group.member_of_user(current_user)
      render_forbidden if current_member.member?
    end

    def check_delete_permission!(member)
      current_member = @group.member_of_user(current_user)

      if current_member.member?
        raise StandardError, "The operation is not allowed with member role user"
      end

      if member.admin?
        raise StandardError, "Admin member cannot be deleted"
      end
    end

    def check_update_permission!(member, request_role)
      current_member = @group.member_of_user(current_user)

      if current_member.member?
        raise StandardError, "The operation is not allowed with member role user"
      end

      if request_role == :admin && !current_member.admin?
        raise StandardError, "Only admin can promote to admin"
      end

      if member.admin?
        raise StandardError, "Cannot change admin role"
      end
    end
  end
end
