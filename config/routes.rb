CruiseControl::Application.routes.draw do
  match '/' => 'projects#index', :as => :root
  match 'projects/code/:id/*path' => 'projects#code', :as => :code
  
  resources :projects do
    member do
      post :build, :constraints => { :id => /.*/ }
      post :kill_build, :constraints => { :id => /.*/ }
      get :getting_started, :constraints => { :id => /.*/ }
    end
  end

  match 'builds/:project/latest_successful(/*path)' => 'builds#latest_successful', :as => :latest_successful_build, :project => /[^\/]+/
  match 'builds/:project/:build/artifacts/*path' => 'builds#artifact', :as => :build_artifact, :build => /[^\/]+/, :project => /[^\/]+/
  match 'builds/:project/:build' => 'builds#show', :as => :build, :build => /[^\/]+/, :project => /[^\/]+/
  match 'builds/:project' => 'builds#show', :as => :project_without_builds, :project => /[^\/]+/

  match 'documentation/plugins' => 'documentation#plugins', :as => :plugin_doc_list
  match 'documentation/plugins/:type/:name' => 'documentation#plugins', :as => :plugin_doc, :name => /[^\/]+/

  match 'documentation/*path' => 'documentation#get', :as => :document
  match 'documentation' => 'documentation#get', :as => :document_root
  
  match 'XmlStatusReport.aspx' => 'projects#index', :format => 'cctray'
  match 'XmlServerReport.aspx' => 'projects#index', :format => 'cctray'

  # TODO Remove this.
  match '/:controller(/:action(/:id))'
end
