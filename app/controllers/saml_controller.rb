class SamlController < ApplicationController
  skip_before_filter :authenticate!

  def init
    request = Onelogin::Saml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume
    response = Onelogin::Saml::Response.new(params[:SAMLResponse])
    response.settings = saml_settings
    if response.is_valid?
      current_user = User.find_by_email(response.name_id)
      # path = session[:attempted_path] ||
      # session[:attempted_path] = nil
      # redirect_to path and return
      logger.info(response.document)
      render :text => "Authenticated as #{response.inspect}"
    else
      render :text => "Failure"
    end
  end

  private

  def saml_settings
    settings = Onelogin::Saml::Settings.new

    settings.assertion_consumer_service_url = saml_consume_url(host: request.host)
    settings.issuer                         = "http://#{request.port == 80 ? request.host : request.host_with_port}"
    settings.idp_sso_target_url             = SAML_SETTINGS[:idp_sso_target_url]
    settings.idp_cert_fingerprint           = SAML_SETTINGS[:idp_cert_fingerprint]
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
    # Optional for most SAML IdPs
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"

    settings
  end
end