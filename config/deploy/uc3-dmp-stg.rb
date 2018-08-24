set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-stg.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, 'dmp/apps/dmp/shared'

# Define the location of the configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'dmptool-stage'

# Pull in shibboleth IdP selection pages
append :linked_files, 'public/eds.html',
                      'public/fullDiscoFeed.json',
                      'public/idpselect_config.js',
                      'public/idpselect.css',
                      'public/idpselect.js',
                      'public/localDiscoFeed.json'

# We are running stage as if it were a prod environment right now
set :rails_env, 'production'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

namespace :git do
  after :create_release, 'move_compiled_jpegs'
  after :create_release, 'swap_in_stage'

  # Webpack will compile and place SASS requests for `background: url('file.jpg')` into the root public/ dir
  # the compiled CSS though will look for these files in public/stylesheets so we need to move them over
  desc 'Transfer compiled JPEGs over to the public/stylesheets dir'
  task :move_compiled_jpegs do
    on roles(:app), wait: 10 do
      execute "cd #{release_path}/public && ls -1 | egrep '[a-zA-Z0-9]{32}\\.[jpg|png]' | xargs mv -t #{release_path}/public/stylesheets"
    end
  end

  desc "Swap in Stage server database/secrets configs and production.rb"
  task :swap_in_stage do
    on roles(:app), wait: 1 do
      execute "cd #{release_path} && cat config/database.yml | sed 's/production:/live:/' >> config/database.yml"
      execute "cd #{release_path} && cat config/database.yml | sed 's/stage:/production:/' >> config/database.yml"
      execute "cd #{release_path} && cat config/secrets.yml | sed 's/production:/live:/' >> config/database.yml"
      execute "cd #{release_path} && cat config/secrets.yml | sed 's/stage:/production:/' >> config/database.yml"
      execute "cd #{release_path} && cat config/environments/production.rb | sed 's/config.log_level = :warn/config.log_level = :debug/' >> config/environments/production.rb"
    end
  end
end