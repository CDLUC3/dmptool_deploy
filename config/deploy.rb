# config valid only for current version of Capistrano
lock "3.11.0"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp unless ENV['BRANCH']
set :branch, ENV['BRANCH'] if ENV['BRANCH']

set :default_env, { path: "/dmp/local/bin:$PATH" }

# Default environments to skip
set :bundle_without, %w{ puma pgsql thin rollbar test }.join(' ')

# Define the location of the private configuration repo
set :config_repo, 'git@github.com:cdlib/dmptool_config.git'

# Default value for :linked_files is []
append :linked_files, 'config/database.yml',
                      'config/secrets.yml',
                      'config/branding.yml',
                      'config/initializers/recaptcha.rb',
                      'config/initializers/contact_us.rb',
                      'config/initializers/devise.rb',
                      'config/initializers/wicked_pdf.rb'

# Default value for linked_dirs is []
append :linked_dirs, 'log',
                     'tmp/pids',
                     'tmp/cache',
                     'tmp/sockets',
                     'public/system'

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  # STILL NEEDED FOR PROD
  #after :deploy, 'cleanup:remove_example_configs'

  before :deploy, 'config:install_shared_dir'
  after :deploy, 'cleanup:restart_passenger'

# FOR NEW Roadmap 2.x configuration
# TODO: Uncomment this for deployments to dmp-dev or roadmap-stg and permenantly once we have
#       merged the latest changes into dmptool stage and prod
#  namespace :assets do
#    before :backup_manifest, 'deploy:create_asset_manifests'
#  end

#  desc 'Create an empty assets manifest to satisfy Capistrano rails assets gem'
#  task :create_asset_manifests do
#    on roles(:app), wait: 1 do
#      execute "cd #{release_path} && mkdir -p public/assets"
#      execute "cd #{release_path} && touch public/assets/manifest.json"
#      execute "cd #{release_path} && touch public/assets/.sprockets-manifest.json"
#    end
#  end
end

#namespace :git do
  # STILL NEEDED FOR PROD
  #after :create_release, 'remove_postgres'

  # v2.0
  #after :create_release, 'create_asset_manifests'

  # STILL NEEDED FOR PROD
  #desc 'Remove the postgres dependency from the Gemfile'
  #task :remove_postgres do
  #  on roles(:app), wait: 1 do
      # Comment out the Postgres gem
  #    execute "cd #{release_path} && mv Gemfile Gemfile.bak"
  #    execute "cd #{release_path} && cat Gemfile.bak | sed 's/gem \\x27pg\\x27/#gem \\x27pg\\x27/' >> Gemfile"
  #    execute "cd #{release_path} && bundle install"

      # FOR NEW Roadmap 2.x configuration
      #execute "cd #{release_path} && bundle install --without puma psql thin"
  #  end
  #end
#end

namespace :config do
  desc 'Setup up the config repo as the shared directory'
  task :install_shared_dir do
    on roles(:app), wait: 1 do
      execute "if [ ! -d '#{deploy_path}/shared/' ]; then cd #{deploy_path}/ && git clone #{fetch :config_repo} shared; fi"
      execute "cd #{deploy_path}/shared/ && git checkout #{fetch :config_branch} && git pull origin #{fetch :config_branch}"
    end
  end
end

namespace :cleanup do
  # STILL NEEDED FOR PROD
  # this prevents examples from being used on the server
  #desc "Remove all of the example config files"
  #task :remove_example_configs do
  #  on roles(:app), wait: 1 do
  #    execute "rm -f #{release_path}/config/*.yml.sample"
  #    execute "rm -f #{release_path}/config/initializers/contac_us_example.rb"
  #    execute "rm -f #{release_path}/config/initializers/*.rb.example"
  #  end
  #end

  desc 'Restart Phusion Passenger'
  task :restart_passenger do
    on roles(:app), wait: 5 do
      execute "cd /apps/dmp/init.d && ./passenger-dmp.dmp restart"
    end
  end

  after :restart_passenger, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
end
