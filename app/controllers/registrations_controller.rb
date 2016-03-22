class RegistrationsController < Devise::RegistrationsController
  before_filter :configure_permitted_parameters, :only => [:create]

  # POST /resource
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?

      # Inject Mailchimp Integration
      begin
        mailchimp = Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
        results = mailchimp.lists.subscribe(ENV['MAILCHIMP_LIST_ID'], { email: resource.email })
        Rails.logger.info("Subscribed user to mailchimp: #{results.inspect}")
      rescue => ex
        Rails.logger.error("Unable to subscribe user to Mailchimp: #{ex.message}")
      end

      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone, :referer_id, :i_agree) }
  end
end
