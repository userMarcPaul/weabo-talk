# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    layout "devise", only: [ :new, :create ]

    # Before attempting to sign in, check if account is unconfirmed
    before_action :check_unconfirmed_account, only: [ :create ]

    # Override destroy action to provide better UX
    def destroy
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out
      yield if block_given?
      redirect_to root_path
    end

    private

    # Only after a correct password, so the sign-in form doesn't reveal which emails
    # have unconfirmed accounts. find_for_authentication applies Devise's email
    # normalization (case, whitespace).
    def check_unconfirmed_account
      user = User.find_for_authentication(email: sign_in_params[:email])
      if user && user.inactive_message == :unconfirmed && !user.active_for_authentication? &&
         user.valid_password?(sign_in_params[:password])
        flash.alert = "⚠️ Please confirm your email first. Check your inbox for the confirmation email, or click below to resend it."
        redirect_to new_user_confirmation_path(email: user.email)
      end
    end
  end
end
