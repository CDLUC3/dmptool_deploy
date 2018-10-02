set :application, 'DMPRoadmap'
set :repo_url, 'https://github.com/DMPRoadmap/roadmap.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-roadmap-stg.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/roadmap'
set :share_to, 'dmp/apps/roadmap/shared'

# Define the location of the private configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'roadmap'

set :rails_env, 'development'

set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"