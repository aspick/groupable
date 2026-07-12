module Groupable
  class GroupsController < ApplicationController
    before_action :set_group, only: [ :show, :update, :destroy ]

    # GET /groupable/groups
    def index
      @groups = current_user.groupable_groups.active
      render json: @groups
    end

    # GET /groupable/groups/:id
    def show
      render json: @group
    end

    # POST /groupable/groups
    def create
      @group = group_class.create_new_group!(
        group_params[:name],
        current_user
      )

      render json: @group, status: :created
    end

    # PATCH/PUT /groupable/groups/:id
    def update
      unless can_edit_group?
        return render_forbidden
      end

      @group.update!(group_params)
      render json: @group
    end

    # DELETE /groupable/groups/:id
    def destroy
      unless can_delete_group?
        return render_forbidden
      end

      @group.update!(active: false)
      head :no_content
    end

    private

    def set_group
      @group = find_current_user_group(params[:id])
    end

    def group_params
      params.require(:item).permit(:name)
    end

    def can_edit_group?
      current_member && (current_member.editor? || current_member.admin?)
    end

    def can_delete_group?
      current_member&.admin?
    end
  end
end
