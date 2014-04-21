class Goal < ActiveRecord::Base

  include ModelBase
  
  hobo_model # Don't put anything above this

  fields do
    name :string
    timestamps
  end
  attr_accessible :name, :hoshin, :hoshin_id, :company_id, :creator_id
  
  belongs_to :creator, :class_name => "User", :creator => true
  
  belongs_to :hoshin, :inverse_of => :goals, :counter_cache => true
  
  belongs_to :company
  
  acts_as_list :scope => :hoshin
  
  default_scope lambda { 
    where(:company_id => UserCompany.select(:company_id)
      .where('user_id=?',  
        User.current_id) ) }
  
  before_create do |goal|
    h = Hoshin.unscoped.find(goal.hoshin_id)
    goal.company = h.company
  end
  
  after_create do |obj|
    user = User.current_user
    user.tutorial_step << :goal
    user.save!
  end
  

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || same_company
  end

  def update_permitted?
    acting_user.administrator? || same_company
  end

  def destroy_permitted?
    acting_user.administrator? || same_company_admin
  end

  def view_permitted?(field)
    acting_user.administrator? || same_company
  end

end
