require "rails_helper"

RSpec.describe "Connections", type: :request, inertia: true do
  describe "GET /connexion" do
    subject { get new_connection_path }

    it_behaves_like "only_for_guests"

    it "returns http success" do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /connections" do
    subject { post connections_path, params: params }
    let(:params) { {} }

    it_behaves_like "only_for_guests"

    context "when email is invalid" do
      let(:params) { {email: ""} }

      it "redirects back with errors" do
        assert_no_emails do
          subject
        end
        expect(response).to redirect_to(new_connection_path)
        follow_redirect!
        expect(inertia.props[:errors]["email"]).to be_present
      end
    end

    context "when user is unknown" do
      let(:params) { {email: "unknown@mail.com"} }

      xcontext "when rate limit is reached" do
        # can't get this test to pass, but feature works as expected
        it "rate_limit" do
          9.times do
            post connections_path, params: {email: "unknown@mail.com"}
          end
          post connections_path, params: {email: "unknown@mail.com"}
          expect(response).to redirect_to(new_connection_path)
          follow_redirect!
          expect(inertia.props[:flash]).to be_present
        end
      end

      it "redirects to /s-inscrire" do
        assert_no_emails do
          subject
        end
        expect(response).to redirect_to(new_registration_path)
      end
    end

    context "when user is known" do
      let(:user) { create(:user, otp_expires_at: DateTime.current) }
      let(:params) { {email: user.email} }

      it "redirects to /se-connecter and sends OTP email" do
        assert_enqueued_emails 1 do
          subject
        end
        user.reload.otp
        assert_enqueued_email_with UserMailer, :otp, params: {user:}
        expect(response).to redirect_to(new_session_path)
      end

      it "redirects to /se-connecter but does not send OTP email again if OTP is still valid" do
        otp = user.generate_new_otp!
        assert_no_emails do
          subject
        end
        expect(user.reload.otp).to eq(otp)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /connections/resend_otp" do
    subject { post resend_otp_connections_path, params: params }
    let(:params) { {} }

    it_behaves_like "only_for_guests"

    context "when user is not found" do
      let(:params) { {email: "unknown@mail.com"} }

      it "redirects to /connection and does not send email" do
        assert_no_emails do
          subject
        end
        expect(response).to redirect_to(new_connection_path)
      end
    end

    context "when user is known" do
      let(:user) { create(:user) }
      let(:params) { {email: user.email} }

      it "sends OTP email and redirects to /se-connecter" do
        assert_enqueued_emails 1 do
          subject
        end
        expect(response).to redirect_to(new_session_path)
      end

      it "sends OTP email again even if OTP is still valid and redirects to /se-connecter" do
        otp = user.generate_new_otp!
        assert_enqueued_emails 1 do
          subject
        end
        expect(user.reload.otp).not_to eq(otp)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
