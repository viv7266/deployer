role :app, %w{deployer@127.0.0.1}
set :filter, :hosts => %w{127.0.0.1}
set :environment, "production"
set :application, 'backend'
set :repo_url, 'git@github.com:viv7266/trial.git'
set :deploy_to, "/home/deployer/trial"
set :port, "8080"
set :user, "deployer"
set :server_start_wait, 180
set :traffic_stop_wait, 35
set :traffic_start_wait, 35
set :app_cmd_wait_start, 180 # Second
set :app_cmd_wait_stop, 60 # Second
set :established_connections_number, 4
set :ssh_options, {
    forward_agent: true,
}
set :dry_run, ENV['dry_run']
