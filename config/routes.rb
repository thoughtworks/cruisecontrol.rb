CruiseControl::Application.routes.draw do
  match '/' => 'projects#index'
  
  resources :projects do  
    member do
      post :build
      get :getting_started
    end
  end

  match 'builds/older/:project' => 'builds#drop_down', :as => :builds_drop_down
  match 'builds/:project/:build/*path' => 'builds#artifact', :as => :build_artifact, :build => /[^\/]+/
  match 'builds/:project/:build' => 'builds#show', :as => :build, :build => /[^\/]+/
  match 'builds/:project' => 'builds#show', :as => :project_without_builds

  match 'projects/code/:id/*path' => 'projects#code', :as => :code

  match 'documentation/plugins' => 'documentation#plugins', :as => :plugin_doc_list
  match 'documentation/plugins/:type/:name' => 'documentation#plugins', :as => :plugin_doc, :name => /[^\/]+/

  match 'documentation/*path' => 'documentation#get', :as => :document
  match 'documentation' => 'documentation#get', :as => :document_root
  
  match 'XmlStatusReport.aspx' => 'projects#index', :format => 'cctray'
  match 'XmlServerReport.aspx' => 'projects#index', :format => 'cctray'

  # TODO Remove this.
  match '/:controller(/:action(/:id))'
end