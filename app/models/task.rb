class Task < ActiveRecord::Base

  include ModelBase
  
  hobo_model # Don't put anything above this

  fields do
    name              :string
    description       HoboFields::Types::TextileString
    deadline          :date
    original_deadline :date
    show_on_parent    :boolean
    reminder          :boolean, :default => true
    timestamps
  end
  attr_accessible :name, :objective, :objective_id, :description, :responsible, :responsible_id, :reminder,
    :deadline, :original_deadline, :area, :area_id, :show_on_parent, :company, :company_id, :creator_id

  belongs_to :creator, :class_name => "User", :creator => true
  
  belongs_to :company
  
  belongs_to :objective, :inverse_of => :tasks, :counter_cache => true
  belongs_to :area, :inverse_of => :tasks, :counter_cache => false
  belongs_to :responsible, :class_name => "User", :inverse_of => :tasks
  
  acts_as_list :scope => :area, :column => "tsk_pos"
  
  set_default_order [:status, :tsk_pos]
  
  validate :validate_company
  
  default_scope lambda { 
    where(:company_id => UserCompany.select(:company_id)
      .where('user_id=?',  
        User.current_id)) }
  
  before_create do |task|
    task.company = task.objective.company
  end
  
  after_create do |obj|
    user = User.current_user
    user.tutorial_step << :task
    user.save!
  end

  lifecycle :state_field => :status do
    state :active, :default => true
    state :completed, :discarded, :deleted
    
    transition :activate, {nil => :active}, :available_to => "User" 
    
    transition :complete, {:active => :completed}, :available_to => "User" 
    
    transition :discard, {:active => :discarded}, :available_to => "User" 
    
    transition :reactivate, {:completed => :active}, :available_to => "User" 
    transition :reactivate, {:discarded => :active}, :available_to => "User" 
    
    transition :delete, {:completed => :deleted}, :available_to => "User" 
    transition :delete, {:discarded => :deleted}, :available_to => "User" 
      
  end
  
  before_save do |task|
    if task.original_deadline.nil? && !task.deadline.nil?
      task.original_deadline = task.deadline
    end
  end
  
  def position
    tsk_pos
  end
  
  def deadline_status 
    if deadline?
      deadline < Date.today ? :overdue : :current
    end
  end
  
  def deviation
    if !deadline.nil? && !original_deadline.nil?
      (deadline - original_deadline).to_i
    else
      0
    end
  end
  
  # --- Permissions --- #
  
  def validate_company
    errors.add(:company, "You don't have permissions on this company") unless same_company
  end
  
  def create_permitted?
    same_company
  end

  def update_permitted?
    same_company
  end

  def destroy_permitted?
    same_company_admin
  end

  def view_permitted?(field)
    same_company
  end

end

class ChildTask < Task
end
