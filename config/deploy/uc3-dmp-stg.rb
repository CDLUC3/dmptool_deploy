set :application, 'DMPTool'
#set :repo_url, 'https://github.com/DMPRoadmap/roadmap.git'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:
set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-stg.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

# Default deploy_to directory is /var/www/my_app_name
set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, 'dmp/apps/dmp/shared'

# Define the location of the configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'master'

# Copy over the homepage images
append :linked_files, 'lib/assets/images/homepage/*.*'

# Pull in shibboleth IdP selection pages
#append :linked_files, 'public/eds.html',
#                      'public/fullDiscoFeed.json',
#                      'public/idpselect_config.js',
#                      'public/idpselect.css',
#                      'public/idpselect.js',
#                      'public/localDiscoFeed.json'

# Default environments to skip
set :bundle_without, %w{development test}.join(' ')

# We are running stage as if it were a prod environment right now
set :rails_env, 'production'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

namespace :git do
  after :create_release, 'npm_install'
  after :create_release, 'webpack_bundle'
  after :create_release, 'move_compiled_jpegs'
  after :create_release, 'swap_in_stage'

  desc 'Install all of the resources managed by NPM'
  task :npm_install do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm install && cd .."
    end
  end

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

  desc "Swap in Stage server database/secrets configs and production.rb"
  task :swap_in_stage do
    on roles(:app), wait: 1 do
      execute "cd #{release_path} && cat config/database.yml | sed 's/production:/live:/' >> config/database2.yml"
      execute "cd #{release_path} && cat config/database2.yml | sed 's/stage:/production:/' >> config/database.yml"
      execute "cd #{release_path} && cat config/secrets.yml | sed 's/production:/live:/' >> config/secrets2.yml"
      execute "cd #{release_path} && cat config/secrets2.yml | sed 's/stage:/production:/' >> config/secrets.yml"
      execute "cd #{release_path} && cat config/environments/production.rb | sed 's/config.log_level = :warn/config.log_level = :debug/' >> config/environments/production.rb"
    end
  end
end



# TODO: The snippet below is for use with the new DMPRoadmap changes which overrides the
#       default asset precompilation with a rake task that runs npm and webpack
=begin
set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-stg.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, 'dmp/apps/dmp/shared'

# Define the location of the private configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'master'

set :rails_env, 'production'

set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

# We are running stage as if it were a prod environment right now
namespace :deploy do
  after :deploy, 'move_compiled_jpegs'

  # Webpack will compile and place SASS requests for `background: url('file.jpg')` into the root public/ dir
  # the compiled CSS though will look for these files in public/stylesheets so we need to move them over
  desc 'Transfer compiled JPEGs over to the public/stylesheets dir'
  task :move_compiled_jpegs do
    on roles(:app), wait: 10 do
      execute "cd #{release_path}/public && ls -1 | egrep '[a-zA-Z0-9]{32}\\.[jpg|png]' | xargs mv -t #{release_path}/public/stylesheets"
    end
  end
end

namespace :git do
  after :create_release, 'swap_in_stage'

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
=end