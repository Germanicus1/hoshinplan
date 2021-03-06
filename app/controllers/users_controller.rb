class UsersController < ApplicationController
  
  hobo_user_controller  
  
  show_action :dashboard, :tutorial, :pending, :unsubscribe
  
  # Allow only the omniauth_callback action to skip the condition that
  # we're logged in. my_login_required is defined in application_controller.rb.
  skip_before_filter :my_login_required, :only => :omniauth_callback
  
  after_filter :update_data, :only => :omniauth_callback
  
  auto_actions :all, :except => [ :index, :new, :create ]
    
  include HoboOmniauth::Controller
  
  include RestController
  
  def create_auth_cookie
    cookies[:auth_token] = { :value => "#{current_user.remember_token} #{current_user.class.name}",
                                   :expires => current_user.remember_token_expires_at, :domain => :all }
  end
  
  def do_activate
    do_transition_action :activate do
      self.current_user = model.find(params[:id])
      redirect_to home_page
    end
  end
  
  def admin_only
      render :text => "Permission Denied", :status => 403 unless current_user.administrator?
  end
  
  def dashboard
    redirect_to current_user
  end
  
  def show
    begin
      self.this = User.includes({:user_companies => {:company => :hoshins}}).where(:id => params[:id]).first 
      raise Hobo::PermissionDeniedError if self.this.nil?
      name = self.this.name.nil? ? self.this.email_address : self.this.name
      @page_title = I18n.translate('user.dashboard_for', :name => name, 
        :default => 'Dashboard for ' + name)     
      hobo_show
    rescue Hobo::PermissionDeniedError => e
      self.current_user = nil
      redirect_to "/login?force=true"
    end
  end
  
  def login
    unless params[:force]
      hobo_login do
        if performed?
          redirect_to home_page 
        else
          true #continue normal hobo_login behavior
        end
      end
    end
  end
    
  
  def pending
    begin
      self.this = User.includes({:user_companies => {:company => :hoshins}}).where(:id => params[:id]).first 
      @page_title = I18n.translate('user.pending_actions_for', :name => self.this.name, 
        :default => 'Pending actions for ' + self.this.name)      
    rescue Hobo::PermissionDeniedError => e
      self.current_user = nil
      redirect_to "/login?force=true"
    end
  end
  
  def unsubscribe
    @this = find_instance
  end

  def tutorial
    @this = find_instance
  end
  
  def logout_and_return
    logout_current_user
    redirect_to params["return_url"]
  end
  
  # Normally, users should be created via the user lifecycle, except
  #  for the initial user created via the form on the front screen on
  #  first run.  This method creates the initial user.
  def create
    hobo_create do
      if valid?
        self.current_user = this
        flash[:notice] = t("hobo.messages.you_are_site_admin", :default=>"You are now the site administrator")
        redirect_to home_page
      end
    end
  end
  
  def update
    ajax = request.xhr?
    self.this = find_instance
    
    if self.this.timezone.nil? && !cookies[:tz].nil?
   	  zone = cookies[:tz]
   	  zone = Hoshinplan::Timezone.get(zone)
      self.this.timezone = zone.name unless zone.nil?
    end
    if params[:user] && params[:user][:preferred_view]
      ajax = true
    end
    if params[:tutorial_step] 
      step = params[:tutorial_step].to_i
      if step == 1
        self.this.tutorial_step << self.this.next_tutorial
      elsif step == -1
        self.this.tutorial_step.pop
      elsif step > 1
        self.this.tutorial_step = User.values_for_tutorial_step
      elsif step < -1
        self.this.tutorial_step = []
      end
      if !params[:user]
        params[:user] = {}
      end
      params[:user][:tutorial_step] = self.this.tutorial_step
      ajax = true
    end
    hobo_update do
      if ajax
        hobo_ajax_response
      else
        redirect_to current_user, :dgv => Time.now.to_i if valid?
      end
    end
  end
  
  def update_data
    auth = request.env["omniauth.auth"]
    authorization = Authorization.find_by_provider_and_uid(auth['provider'], auth['uid'])
    authorization ||= Authorization.find_by_email_address(auth['info']['email'])
    atts = authorization.attributes.slice(*model.accessible_attributes.to_a)
    # PATCH: InfoJobs Open Id returns only the family name as the name and the full name in nickname... Strange...
    domain = current_user.email_address.split("@").last
    if (domain == "infojobs.net" || domain == "lectiva.com" || domain == "scmspain.com")
      atts['name'] = auth['info']['nickname']
    end
    atts.each { |k, v| 
      atts.delete(k) if !current_user.attributes[k].blank? || v.nil?
    }
    begin
      current_user.attributes = atts
    rescue
      current_user.attributes = atts.delete('photo')
    end
    if current_user.lifecycle.state.name == :invited
      current_user.lifecycle.activate!(current_user)
    end
    if current_user.timezone.nil? && !cookies[:tz].nil?
   	  zone = cookies[:tz]
   	  zone = Hoshinplan::Timezone.get(zone)
      current_user.timezone = zone.name unless zone.nil?
    end
    if current_user.language.nil?
      current_user.language = I18n.locale
    end
    begin
      current_user.save!
    rescue ActiveRecord::RecordInvalid => invalid
      fail ActiveRecord::RecordInvalid, invalid.record.errors.to_yaml
    end
  end
  
  def sign_in(user) 
    sign_user_in(user)
  end
  
  def sign_user_in(user, password=nil)
    params[:remember_me] = true
    if (password.nil?)
      super(user)
    else
      super(user, password)
    end
    current_user.remember_me if logged_in?
    create_auth_cookie if logged_in?
  end
  
end
