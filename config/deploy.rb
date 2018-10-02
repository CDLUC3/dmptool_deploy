# config valid only for current version of Capistrano
lock "3.8.1"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp unless ENV['BRANCH']
set :branch, ENV['BRANCH'] if ENV['BRANCH']

# Default environments to skip
set :bundle_without, %w{test}.join(' ')

# Default value for :linked_files is []
append :linked_files, 'config/database.yml',
                      'config/secrets.yml',
                      'config/branding.yml',
                      'config/initializers/recaptcha.rb',
                      'config/initializers/contact_us.rb',
                      'config/initializers/devise.rb',
                      'config/initializers/wicked_pdf.rb'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'config/environments'

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  before :deploy, 'config:install_shared_dir'
  after :deploy, 'cleanup:remove_example_configs'
  after :deploy, 'cleanup:restart_passenger'

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

namespace :git do
  after :create_release, 'remove_postgres'
  #after :create_release, 'create_asset_manifests'

  desc 'Remove the postgres dependency from the Gemfile'
  task :remove_postgres do
    on roles(:app), wait: 1 do
      # Comment out the Postgres gem
      execute "cd #{release_path} && mv Gemfile Gemfile.bak"
      execute "cd #{release_path} && cat Gemfile.bak | sed 's/gem \\x27pg\\x27/#gem \\x27pg\\x27/' >> Gemfile"
      execute "cd #{release_path} && bundle install"
    end
  end
end

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
  # this prevents examples from being used on the server
  desc "Remove all of the example config files"
  task :remove_example_configs do
    on roles(:app), wait: 1 do
      execute "rm -f #{release_path}/config/*_example.yml"
      execute "rm -f #{release_path}/config/initializers/contac_us_example.rb"
      execute "rm -f #{release_path}/config/initializers/*.rb.example"
    end
  end

  desc 'Restart Phusion Passenger'
  task :restart_passenger do
    on roles(:app), wait: 5 do
      execute "#{fetch :passenger_restart}"
    end
  end

  after :restart_passenger, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
end
