class RegistrationsController < ApplicationController
  skip_before_action :authenticate
  before_action :already_authenticated

  before_action :verify_captcha, only: [ :create ]
  before_action :add_terms_and_privacy_accepted_at, only: [ :create ]

  rate_limit to: 100, within: 1.day, only: :create

  def new
    render inertia: "Auth/SignUp"
  end

  def create
    user = User.new(user_params)

    if user.save
      user.send_otp_email
      redirect_to new_session_path
    else
      redirect_to new_registration_path, inertia: { errors: user.errors }
    end
  end

  private

    def add_terms_and_privacy_accepted_at
      params.delete(:terms_and_privacy_accepted_at) # avoid hacking of terms_and_privacy_accepted_at
      if accepts_conditions?
        params[:terms_and_privacy_accepted_at] = DateTime.current
      end
    end

    def verify_captcha
      captcha = Captcha.new(params.delete(:recaptcha_token))
      unless captcha.valid?
        redirect_to new_registration_path, error: "Erreur de validation du CAPTCHA. Veuillez réessayer."
      end
    end

    def user_params
      params.permit(:email, :first_name, :last_name, :terms_and_privacy_accepted_at)
    end

    def accepts_conditions?
      # BUG : in test environment, the boolean true is received as a string 'true'
      ActiveModel::Type::Boolean.new.cast(params[:accepts_conditions])
    end
end
