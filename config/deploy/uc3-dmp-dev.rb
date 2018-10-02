set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-dev.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, '/dmp/apps/dmp/shared'

# Copy over the homepage images
append :linked_files, 'lib/assets/images/homepage/*.*'

# Define the location of the private configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'master'

set :rails_env, 'development'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"
