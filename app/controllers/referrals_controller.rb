class ReferralsController < ApplicationController
  before_filter :authenticate_user!, only: [:index]

  def index
    @referral_code = current_user.try(:id)
  end

  def join
    @referer = User.where(id: params[:referral]).first
    if @referer.blank?
      redirect_to root_path and return
    else
      @user = User.new(referer_id: @referer.id)
      cookies[:referral] = { :value => @referer.id, :expires => 5.days.from_now }
    end
  end
end
