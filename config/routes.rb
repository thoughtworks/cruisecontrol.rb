ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)
  
  # Sample resource route (maps HTTP verbs to controller actions automatically):
  # map.resources :products

  # Sample resource route with options:
  # map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }
  
  # map.connect 'build', :controller => 'build', :action => "index"

  map.resources :projects

  map.project_without_builds 'builds/:project', :controller => 'builds', :action => 'show'
  map.build 'builds/:project/:build', :controller => 'builds', :action => 'show', :build => /[^\/]+/
  map.connect 'builds/:project/:build/*artifact_path', :controller => 'builds', :action => 'artifact', :build => /[^\/]+/
  
  map.connect 'projects/code/:project/*path', :controller => 'projects', :action => 'code'
  
  map.connect '', :controller => 'projects', :action => 'index'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'


  # Route for CCTray.NET
  map.connect 'XmlStatusReport.aspx', :controller => 'status', :action => 'projects'
end
