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

set :rails_env, 'production'

set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

namespace :git do
  after :create_release, 'remove_postgres'
  after :create_release, 'npm_install'
  after :create_release, 'webpack_bundle'

  desc 'Remove the postgres dependency from the Gemfile'
  task :remove_postgres do
    on roles(:app), wait: 1 do
      execute "cd #{release_path} && bundle install --without puma psql thin"
    end
  end

  desc 'Install all of the resources managed by NPM'
  task :npm_install do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm install && cd .."
    end
  end

  desc 'Bundle the Webpack managed assets'
  task :webpack_bundle do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm run bundle -- -p --no-watch"
    end
  end
end