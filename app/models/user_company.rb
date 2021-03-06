class UserCompany < ActiveRecord::Base

  include ModelBase
  
  
  hobo_model # Don't put anything above this

  fields do 
    timestamps
  end
  attr_accessible :company, :company_id, :user, :user_id
  index [:user_id, :company_id]
  
  belongs_to  :company, :accessible => true
  belongs_to  :user, :accessible => true
 
  #validate :company_admin_validator
  
  default_scope lambda { 
    where("user_companies.company_id = ?", Company.current_id) if Company.current_id }  
  
  def company_admin_validator
    if acting_user.nil?
      errors.add(:company, "you have to be logged in" ) 
    else
      errors.add(:company, "you must be an administrator of \"" + company.name + 
        "\" to be able to associate users to it.") unless company_admin || new_company_available
    end
  end
  
  before_destroy do |uc|
    Indicator.where(:company_id => uc.company_id, :responsible_id => uc.user_id).update_all(:responsible_id => nil)
    Task.where(:company_id => uc.company_id, :responsible_id => uc.user_id).update_all(:responsible_id => nil)
  end
  
  def company_admin
    self.company.nil? || #!self.company_changed? ||
    acting_user.user_companies.company_is(self.company).state_is(:admin).exists?
  end
  
  def company_admin_available
    acting_user if company_admin
  end
  
  def accept_available
    return false unless self.lifecycle.valid_key?
    return self.user
  end
 
  new_company_available = Proc.new do |r|
    acting_user if r.company.user_companies.empty?
  end
  
  def activate_ij_available
    domain = self.user.email_address.split("@").last 
    return acting_user if (domain == "infojobs.net" || domain == "lectiva.com")
  end
  
  
  lifecycle do

     state :invited, :active, :admin

     create :invite, :params => [ :company, :user ], :become => :invited,
                      :available_to => "User", :new_key => true do
         UserCompanyMailer.invite(self, company, lifecycle.key, acting_user).deliver
     end
     
     create :activate_ij, :params => [ :company, :user ], :become => :active, :available_to => :activate_ij_available

     transition :revoke_admin, {:invited => :active}, :available_to => :activate_ij_available
     
     transition :resend_invite, { :invited => :invited }, :available_to => :company_admin_available, :new_key => true do
       UserCompanyMailer.invite(self, company, lifecycle.key, acting_user).deliver
     end
     
     create :new_company, :params => [ :company, :user ], :become => :admin
     
     transition :accept, { :invited => :active }, :available_to => :accept_available do
       #user = self.user
       #user.lifecycle.activate!(user)
       #user.save!(:validate => false)
       company.user_companies.where(:state => :admin).each do |admin| 
         UserCompanyMailer.transition(admin.user, user, company, 'accept').deliver
       end
     end
     
     transition :cancel_invitation, { :invited => :destroy }, :available_to => :company_admin_available 

     transition :make_admin, { :active => :admin }, :available_to => :company_admin_available do
       self.save!
       UserCompanyMailer.transition(user, user, company, "admin").deliver
     end
     
     transition :revoke_admin, { :admin => :active }, :available_to => :company_admin_available do
       self.save!
       UserCompanyMailer.transition(user, acting_user, company, "no_admin").deliver
     end
 
     transition :remove, { UserCompany::Lifecycle.states.keys => :destroy }, :available_to => :company_admin_available do 
       UserCompanyMailer.transition(User.find(self.user_id), acting_user, company, "removed").deliver
       Objective.where(:responsible_id => user_id, :company_id => company_id).update_all(:responsible_id => nil)
       Indicator.where(:responsible_id => user_id, :company_id => company_id).update_all(:responsible_id => nil)
       Task.where(:responsible_id => user_id, :company_id => company_id).update_all(:responsible_id => nil)
      end

   end

  # --- Permissions --- #

  def create_permitted?
    true
  end

  def update_permitted?
    user_id = acting_user.id || acting_user.administrator? || acting_user.user_companies.find(company_id).where(:state => :admin).exists?
  end

  def destroy_permitted?
    user_id = acting_user.id || acting_user.administrator? || acting_user.user_companies.find(company_id).where(:state => :admin).exists?
  end

  def view_permitted?(field)
    true
  end

end
