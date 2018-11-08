set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:
set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-prd.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

# Default deploy_to directory is /var/www/my_app_name
set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, 'dmp/apps/dmp/shared'

# Define the location of the configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'master'

# Copy over the homepage images
append :linked_dirs, 'lib/assets/images/homepage'

# Default environments to skip
set :bundle_without, %w{development test}.join(' ')

# We are running stage as if it were a prod environment right now
set :rails_env, 'production'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

namespace :git do
  after :create_release, 'npm_install'

  desc 'Install all of the resources managed by NPM'
  task :npm_install do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm install && cd .."
    end
  end
end

namespace :deploy do
  after :cleanup, 'webpack_bundle'
  after :cleanup, 'move_compiled_jpegs'

  # Update this for Roadmap v2.x
  desc 'Bundle the Webpack managed assets'
  task :webpack_bundle do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm run bundle -- -p"
    end
  end

  # Webpack will compile and place SASS requests for `background: url('file.jpg')` into the root public/ dir
  # the compiled CSS though will look for these files in public/stylesheets so we need to move them over
  desc 'Transfer compiled JPEGs over to the public/stylesheets dir'
  task :move_compiled_jpegs do
    on roles(:app), wait: 10 do
      execute "cd #{release_path}/public && ls -1 | egrep '[a-zA-Z0-9]{32}\\.[jpg|png]' | xargs mv -t #{release_path}/public/stylesheets"
    end
  end
end
