set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:
set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-dev.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

# Default deploy_to directory is /var/www/my_app_name
set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, '/dmp/apps/dmp/shared'

# Define the location of the configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'dmptool'

# Pull in shibboleth IdP selection pages
append :linked_files, 'public/eds.html',
                      'public/fullDiscoFeed.json',
                      'public/idpselect_config.js',
                      'public/idpselect.css',
                      'public/idpselect.js',
                      'public/localDiscoFeed.json'
# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}



# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server "example.com",
#   user: "user_name",
#   roles: %w{web app},
#   ssh_options: {
#     user: "user_name", # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: "please use keys"
#   }

set :rails_env, 'development'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

namespace :git do
  after :create_release, 'npm_install'
  after :create_release, 'webpack_bundle'
  after :create_release, 'move_compiled_jpegs'
  
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
end