Toro::Monitor::Engine.routes.draw do
  get '/', to: 'jobs#index', :as => 'toro_monitor'
  get '/chart', to: 'jobs#chart'
  get '/processes', to: 'processes#index'
  get '/queues', to: 'queues#index'
  
  namespace 'api' do
    get '/jobs', to: 'jobs#index'
    get '/jobs/custom_views/:id', to: 'jobs#custom_views'
    get '/jobs/chart', to: 'jobs#chart'
    get '/jobs/retry/:id', to: 'jobs#retry'
    get '/jobs/statuses', to: 'jobs#statuses'
    get '/processes', to: 'processes#index'
    get '/queues/:queue', to: 'queues#show'
  end
end
