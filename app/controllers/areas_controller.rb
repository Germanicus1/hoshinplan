class AreasController < ApplicationController

  hobo_model_controller

  auto_actions :all, :except => [:index, :new]
  
  include RestController
  
  
end
