class ProfileController < ApplicationController
  before_filter :authenticate_user!

  def show
    if params[:paypal] == '1'
      flash.now[:notice] = 'Payment has been successfully received. Lesson(s) have been added to your account'
    end

    @user = current_user
    if params[:user_id] && current_user.admin?
      @user = user.find(params[:user_id])
    end

    respond_to do |format|
      format.html
      format.json { render json: {
          id: @user.id,
          first_name: @user.first_name,
          last_name: @user.last_name,
          role: @user.role,
          avatar: @user.avatar.thumb.url,
          students: @user.students.map(&:to_simple_json),
          remaining_lessons: @user.lessons.unassigned.count
        }
      }
    end
  end

  def edit
    @user = current_user
  end
end
