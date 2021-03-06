class IndicatorsController < ApplicationController

  hobo_model_controller

  auto_actions :all, :except => :index
  
  auto_actions_for :objective, [:index, :new, :create]
  
  show_action :history
  
  web_method :form
  web_method :value_form
  web_method :delete_history
  
  cache_sweeper :indicators_sweeper
  
  include FrontHelper
  
  
  include RestController
  
  def create
    obj = params["indicator"]
    select_responsible(obj)
    hobo_create
  end
  
  def update
    if params[:history_values]
      error = false
      @this = find_instance
      IndicatorHistory.transaction do
        options = {}
        col_sep = ','
        if t('number.format.separator') == ','
          col_sep = ';'
        end
        options[:col_sep] = col_sep
        idx = 0
        CSV.parse( params[:history_values], options) do |row|
          idx = idx + 1
          if row.length != 4 
            @this.errors.add(:indicator, t("errors.row_invalid_length", :row => idx, :expected => 4, :found => row.length, :sep => col_sep))
            next
          end
          begin
            d = Date.strptime(row[0], t('date.formats.default'))
            if d.year < 1900
              @this.errors.add(:indicator, t("errors.date_format_error", :row => idx, :expected => date_format_default, :found => row[0]))
            end
          rescue ArgumentError
            @this.errors.add(:indicator, t("errors.date_format_error", :row => idx, :expected => date_format_default, :found => row[0]))
          end
          begin
            v = Float row[1].delete(t('number.format.delimiter')).gsub(t('number.format.separator'),'.') unless row[1].nil?
          rescue
            @this.errors.add(:indicator, t("errors.value_format_error", :row => idx, :found => row[1]))
          end
          begin
            g = Float row[2].delete(t('number.format.delimiter')).gsub(t('number.format.separator'),'.') unless row[2].nil?
          rescue
            @this.errors.add(:indicator, t("errors.goal_format_error", :row => idx, :found => row[2]))
          end
          begin
            p = Float row[3].delete(t('number.format.delimiter')).gsub(t('number.format.separator'),'.') unless row[3].nil?
          rescue
            @this.errors.add(:indicator, t("errors.last_format_error", :row => idx, :found => row[3]))
          end
          if @this.errors.messages.length==0
            ih = @this.indicator_histories.find_or_initialize_by(day: d)
            ih.value = v
            ih.goal = g
            ih.previous = p
            begin
            ih.save!
            rescue
             @this.errors.add(:indicator, t("errors.goal_format_error", :row => idx, :found => row[2]))
            end
          end
        end
        if @this.errors.messages.length>0
          raise ActiveRecord::Rollback
        end
        @this.update_from_history!
      end
      redirect_to @this, :action => :history if valid?
      render :history unless valid?
    else
      obj = params[:indicator]
      select_responsible(obj)
      if params[:indicator] && params[:indicator][:value]
        i = find_instance
        i.value = params[:indicator][:value]
        i.value_will_change!
        attributes = {:value => i.value}
        if params[:indicator][:last_update]
          i.last_update = params[:indicator][:last_update]
          i.last_update_will_change!
          attributes = {:value => i.value, :last_update => i.last_update}
        end
        i.save!
        hobo_update(i, :attributes => attributes) do
          redirect_to this.objective.area.hoshin if valid? && !request.xhr?
        end
      else
        hobo_update do
          redirect_to this.objective.area.hoshin if valid? && !request.xhr?
        end
      end
      
    end
  end
  
  def history
      @this = Indicator.find(params[:id])
      if request.xhr?
        hobo_ajax_response
      else
        respond_with(@this)
      end
  end
  
  def delete_history
    @this = find_instance
    IndicatorHistory.delete_all(:indicator_id => @this.id)
    redirect_to @this, :action => :history
  end
  
  def form
    if (params[:id]) 
      @this = find_instance
    else
      @this = Indicator.new
      @this.company_id = params[:company_id]
      @this.objective_id = params[:objective_id]
      @this.area_id = params[:area_id]
    end
  end
  
  def value_form
      @this = find_instance
  end
end
