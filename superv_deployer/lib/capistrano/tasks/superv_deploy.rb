require 'capistrano'
require 'sshkit/backends/netssh'

namespace :supervdeploy do
  desc <<-DESC
    using supervisor for deployment
  DESC
  task :deploy do
    on roles(:app), in: :sequence, wait: 5 do |hosts|
      info '***********Deployment started *****************'
      environment = fetch(:environment) # if different configurations are set for staging and production
      info 'Making server down.'
      mark_server_down
      info 'Waiting to stop traffic.'
      check_traffic_stop
      info 'Traffic has been stopped'
      info 'Stopping API Java Process'
      stop_api_process
      check_api_process_stopped
      info 'API Java Process has been stopped'
      info 'Starting API Java Process'
      start_api_process
      server_start_wait = if fetch(:server_start_wait).to_s.length > 0
                            fetch(:server_start_wait).to_i
                          else
                            90 # Default is 90 sec
                          end
      sleep(server_start_wait)
      check_api_process_started
      directory_permission_update
      if fetch(:dry_run)
        mark_server_up
      end
      check_traffic_start
      info 'Traffic has been started'
      info 'API Java Process has been started'
      puts "        *********************************************************************"
      puts "        *********************************************************************"
      puts "        ***************************     Deployed     ************************"
      puts "        ***************************   Successfully   ************************"
      puts "        *********************************************************************"
      puts "        *********************************************************************"
    end
  end
end

# marking server as down, this is done to remove machine from traffic
def mark_server_down
  current_host = capture("hostname -i").strip
  port = fetch(:port)
  execute :curl, "-X POST", "#{current_host}:#{port}/v1/health/down || exit 0"
end

# marking server as up, this is done to add machine from traffic. if app comes up defaulted to health check ok, it is not required
# it is mandatory for app if deployment started in dry_run mode
def mark_server_up
  while !ask_to_add_traffic do
    sleep(5)
  end
  current_host = capture("hostname -i").strip
  port = fetch(:port)
  execute :curl, "-X POST", "#{current_host}:#{port}/v1/health/up || exit 0"
end

# prompt to wait for user input for adding traffic
def ask_to_add_traffic
  set :server_up, ask('Mark server up to receive traffic y/n', 'n')
  up_y = fetch(:server_up)
  info("Mark server up reponse from user - #{up_y}")
  if fetch(:server_up) == 'y'
    return true
  else
    return false
  end
end


def check_traffic_stop
  # local variables
  traffic_stop_wait = if fetch(:traffic_stop_wait).to_s.length > 0
                        fetch(:traffic_stop_wait).to_i
                      else
                        35 # Default is 35 sec
                      end
  _times = 0

  while check_netstat_traffic do
    if _times >= traffic_stop_wait
      directory_permission_update
      raise 'Traffic is not stopped.'
    end
    _times += 1
    info("Check and wait until Traffic stopping ... #{_times}")
    sleep(1)
  end
  info("sleeping for 10 more seconds after traffic stop")
  sleep(10)
end


def check_traffic_start
  # local variables
  traffic_start_wait = if fetch(:traffic_start_wait).to_s.length > 0
                         fetch(:traffic_start_wait).to_i
                       else
                         35 # Default is 35 sec
                       end
  _times = 0

  while !check_netstat_traffic do
    if _times >= traffic_start_wait
      raise 'Traffic is not started.'
    end
    _times += 1
    info("Check and wait until Traffic starting ... #{_times}")
    sleep(1)
  end
end

# netstat on port to get established TCP connections
def check_netstat_traffic
  port = fetch(:port)
  _netstat = capture("netstat -an | grep \":#{port}\" | grep \"ESTABLISHED\" | wc -l")
  established_connections_number = if fetch(:established_connections_number).to_s.length > 0
                                     fetch(:established_connections_number).to_i
                                   else
                                     4 # Default is 10 sec
                                   end
  if _netstat.to_i > established_connections_number
    return true
  else
    return false
  end
end

# supervisor stop service
def stop_api_process
  application = fetch(:application)
  info capture("sudo /usr/local/bin/supervisorctl stop #{application}")
end

# supervisor start service
def start_api_process
  application = fetch(:application)
  info capture("sudo /usr/local/bin/supervisorctl start #{application}")
end

# if service is started as sudo, update the permission of the user/deploy_to/releases to facilitate rollback
def directory_permission_update
  deploy_to = fetch(:deploy_to)
  user = fetch(:user).to_s
  info capture("sudo chown -R #{user} #{deploy_to}/releases/")
end


def check_api_process_stopped
  # local variables
  app_cmd_wait_stop = if fetch(:app_cmd_wait_stop).to_s.length > 0
                        fetch(:app_cmd_wait_stop).to_i
                      else
                        35 # Default is 35 sec
                      end
  _times = 0
  while check_netstat_api_port do
    if _times >= app_cmd_wait_stop
      directory_permission_update
      raise 'App is not stopped.'
    end
    _times += 1
    info("Check and wait until App stopping ... #{_times}")
    sleep(1)
  end
end

def check_api_process_started
  app_cmd_wait_start = if fetch(:app_cmd_wait_start).to_s.length > 0
                         fetch(:app_cmd_wait_start).to_i
                       else
                         35 # Default is 35 sec
                       end
  _times = 0
  while !check_netstat_api_port do
    if _times >= app_cmd_wait_start
      directory_permission_update
      raise 'App is not started.'
    end
    _times += 1
    info("Check and wait until starting App ... #{_times}")
    sleep(1)
  end
  if fetch(:dry_run)
    mark_server_down
  end
end

# netstat on port to get LISTEN connections
def check_netstat_api_port
  port = fetch(:port)
  _netstat = capture("netstat -an | grep \"#{port}\" | grep \"LISTEN\" ; echo $?")
  info (_netstat)
  if _netstat.to_i == 0
    return true
  else
    return false
  end
end
