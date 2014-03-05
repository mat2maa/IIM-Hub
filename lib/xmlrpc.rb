require 'xmlrpc/client'

class XMLRPC::Client
  def disableSSLVerification
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    warn "Proxyman SSL Verification disabled"
  end
end

