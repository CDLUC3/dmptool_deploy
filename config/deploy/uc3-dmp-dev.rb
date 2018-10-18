set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-dev.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :default_env, { path: "/dmp/local/bin:$PATH" }
set :deploy_to, '/dmp/apps/dmp'
set :share_to, '/dmp/apps/dmp/shared'

# Define the location of the private configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'
set :config_branch, 'master'

set :rails_env, 'development'
set :passenger_restart, "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"

# Roadmap 2.0 move this up to the deploy.rb
# Copy over the homepage images
append :linked_dirs, 'lib/assets/images/homepage'

puts "LINKED DIRS: #{fetch :linked_dirs}"

# Roadmap 2.0 move these tasks up to the deploy.rb
namespace :git do
  after :create_release, 'remove_postgres'
  after :create_release, 'npm_install'

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
end

# Roadmap 2.0 move these tasks up to the deploy.rb
namespace :deploy do
  after :cleanup, 'webpack_bundle'
  after :cleanup, 'move_compiled_jpegs'

  desc 'Bundle the Webpack managed assets'
  task :webpack_bundle do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm run bundle -- -p --no-watch"
    end
  end

  # Webpack will compile and place SASS requests for `background: url('file.jpg')` into the root public/ dir
  # the compiled CSS though will look for these files in public/stylesheets so we need to move them over
  desc 'Transfer compiled JPGs and PNGs over to the public/stylesheets dir'
  task :move_compiled_jpegs do
    on roles(:app), wait: 10 do
      execute "cd #{release_path}/public && ls -1 | egrep '[a-zA-Z0-9]{32}\\.[jpg|png]' | xargs mv -t #{release_path}/public/stylesheets"
    end
  end
end
