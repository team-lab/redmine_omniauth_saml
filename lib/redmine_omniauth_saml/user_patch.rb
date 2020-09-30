require_dependency 'user'

module OmniAuthSamlUser
  def self.prepended(base)
    class << base
      self.prepend(OmniAuthSamlUserMethods)
    end
  end

  module OmniAuthSamlUserMethods
    def find_or_create_from_omniauth(omniauth)
      user_attributes = Redmine::OmniAuthSAML.user_attributes_from_saml omniauth
#     Rails.logger.info "SAML IdP User : " + omniauth.uid
#     Rails.logger.info "SAML Attributes : " + user_attributes.inspect
      user = self.find_by_login(user_attributes[:login])
      unless user
        user = EmailAddress.find_by(address: user_attributes[:mail]).try(:user)
        if user.nil? && Redmine::OmniAuthSAML.onthefly_creation?
#         language,login を SAML Attribute から取らないようにしている
          user = User.new(:status => 1, :language => Setting.default_language)
          user.mail = user_attributes[:mail]
          user.firstname = user_attributes[:firstname]
          user.lastname = user_attributes[:lastname]
          user.created_by_omniauth_saml = true
          user.login = omniauth.uid
          user.activate
          user.save!
          user.reload
        end
      end
      Redmine::OmniAuthSAML.on_login_callback.call(omniauth, user) if Redmine::OmniAuthSAML.on_login_callback
      user
    end
  end


  def change_password_allowed?
    super && !created_by_omniauth_saml?
  end

end

User.prepend(OmniAuthSamlUser)
