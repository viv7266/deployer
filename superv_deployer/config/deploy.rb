require 'capistrano/setup'

lock '3.4.0'
load File.expand_path('../../lib/capistrano/tasks/superv_deploy.rb', __FILE__)

set :scm, :git
set :branch, ENV['branch'] || "develop"
set :keep_releases, 5 # keep last 5 revisions for rollbacks
set :stages, ["staging", "production"]
set :default_stage, "staging"
set :log_level, :info
set :default_shell, '/bin/bash -l'

namespace :build do

  task :setEnvFiles do
    on roles (:app) do
      # set your environment files like aws credentials here
      # add some custom config to your build configurations
      end
    end
  end

after "deploy", "build:setEnvFiles"
after "build:setEnvFiles", "supervdeploy:deploy"
after "deploy:rollback", "supervdeploy:deploy" # in case a rollback is triggered

