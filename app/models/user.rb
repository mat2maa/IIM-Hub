class User < ActiveRecord::Base
  acts_as_authentic {|c|
    c.crypto_provider = Authlogic::CryptoProviders::BCrypt
  }
  serialize :roles, Array
		
	def roles
		(super || []).map {|r| r.to_sym}
	end

	def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end
  

  def password_required?
    crypted_password.blank? || !password.blank?
  end
	
  
end
