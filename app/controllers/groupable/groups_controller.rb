module Groupable
  class GroupsController < ApplicationController
    before_action :set_group, only: [:show, :update, :destroy]

    # GET /groupable/groups
    def index
      @groups = current_user.groupable_groups
      render json: @groups
    end

    # GET /groupable/groups/:id
    def show
      render json: @group
    end

    # POST /groupable/groups
    def create
      @group = Group.create_new_group!(
        group_params[:name],
        current_user
      ) do |group, options|
        # Allow host app to extend group creation
        # via configuration or override
      end

      render json: @group, status: :created
    end

    # PATCH/PUT /groupable/groups/:id
    def update
      unless can_edit_group?(@group)
        return render_forbidden
      end

      @group.update!(group_params)
      render json: @group
    end

    # DELETE /groupable/groups/:id
    def destroy
      unless can_delete_group?(@group)
        return render_forbidden
      end

      @group.update!(active: false)
      head :no_content
    end

    private

    def set_group
      @group = current_user.groupable_groups.find(params[:id])
    end

    def group_params
      params.require(:item).permit(:name)
    end

    def can_edit_group?(group)
      member = group.member_of_user(current_user)
      member && (member.editor? || member.admin?)
    end

    def can_delete_group?(group)
      member = group.member_of_user(current_user)
      member && member.admin?
    end
  end
end
