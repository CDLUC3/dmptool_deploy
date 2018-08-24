set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-dev.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, '/dmp/apps/dmp/shared'

# Define the location of the private configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'dmptool'

# Make sure bundler includes the development gems
set :bundle_without, %w{test}.join(' ')

# Pull in shibboleth IdP selection pages
append :linked_files, 'public/eds.html',
                      'public/fullDiscoFeed.json',
                      'public/idpselect_config.js',
                      'public/idpselect.css',
                      'public/idpselect.js',
                      'public/localDiscoFeed.json'

set :rails_env, 'development'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

namespace :git do
  after :create_release, 'move_compiled_jpegs'

  # Webpack will compile and place SASS requests for `background: url('file.jpg')` into the root public/ dir
  # the compiled CSS though will look for these files in public/stylesheets so we need to move them over
  desc 'Transfer compiled JPEGs over to the public/stylesheets dir'
  task :move_compiled_jpegs do
    on roles(:app), wait: 10 do
      execute "cd #{release_path}/public && ls -1 | egrep '[a-zA-Z0-9]{32}\\.[jpg|png]' | xargs mv -t #{release_path}/public/stylesheets"
    end
  end
end
