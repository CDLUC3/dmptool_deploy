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

set :bundle_without, %w{ puma psql thin }

# Roadmap 2.0 move this up to the deploy.rb
# Copy over the homepage images
append :linked_dirs, 'lib/assets/images/homepage'

# FOR NEW Roadmap 2.x configuration
# TODO: Uncomment this for deployments to dmp-dev or roadmap-stg and permenantly once we have
#       merged the latest changes into dmptool stage and prod
namespace :assets do
  before :backup_manifest, 'deploy:create_asset_manifests'
end

namespace :deploy do
  after :create_release, 'create_asset_manifests'

  desc 'Create an empty assets manifest to satisfy Capistrano rails assets gem'
  task :create_asset_manifests do
    on roles(:app), wait: 1 do
      execute "cd #{release_path} && mkdir -p public/assets"
      execute "cd #{release_path} && touch public/assets/manifest.json"
      execute "cd #{release_path} && touch public/assets/.sprockets-manifest.json"
    end
  end
end

# Roadmap 2.0 move these tasks up to the deploy.rb
#namespace :git do
  #after :create_release, 'remove_postgres'

  #desc 'Remove the postgres dependency from the Gemfile'
  #task :remove_postgres do
  #  on roles(:app), wait: 1 do
  #    execute "cd #{release_path} && bundle install --without puma psql thin"
  #  end
  #end
#end

# Roadmap 2.0 move these tasks up to the deploy.rb
namespace :deploy do
  after :cleanup, 'npm_install'

  desc 'Install all of the resources managed by NPM'
  task :npm_install do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm install && cd .."
    end
  end

  after :npm_install, 'webpack_bundle'

  desc 'Bundle the Webpack managed assets'
  task :webpack_bundle do
    on roles(:app), wait: 1 do
      execute "cd #{release_path}/lib/assets && npm run bundle -- -p --no-watch"
    end
  end

  after :webpack_bundle, 'move_compiled_jpegs'

  # Webpack will compile and place SASS requests for `background: url('file.jpg')` into the root public/ dir
  # the compiled CSS though will look for these files in public/stylesheets so we need to move them over
  desc 'Transfer compiled JPGs and PNGs over to the public/stylesheets dir'
  task :move_compiled_jpegs do
    on roles(:app), wait: 10 do
      execute "cd #{release_path}/public && ls -1 | egrep '[a-zA-Z0-9]{32}\\.[jpg|png]' | xargs mv -t #{release_path}/public/stylesheets"
    end
  end
end
