# config valid only for current version of Capistrano
lock "3.8.1"

# SEE INDIVIDUAL DEPLOY FILES FOR THESE SETTINGS
# --------------------------------------------------
#set :application, "my_app_name"
#set :repo_url, "git@example.com:me/my_repo.git"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp unless ENV['BRANCH']
set :branch, ENV['BRANCH'] if ENV['BRANCH']

# SEE INDIVIDUAL DEPLOY FILES FOR THIS SETTINGS
# --------------------------------------------------
# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, #'assets/images/logo.jpg', 
                      #'assets/stylesheets/admin.css.less', 
                      #'assets/stylesheets/bootstrap_and_overrides.css.less', 
                      'config/database.yml', 
                      'config/secrets.yml', 
                      'config/branding.yml',
                      'config/initializers/recaptcha.rb',
                      'config/initializers/devise.rb',
                      'config/initializers/wicked_pdf.rb',
                      'config/locales/static_pages/de.static.yml',
                      'config/locales/static_pages/en-UK.static.yml',
                      'config/locales/static_pages/en-US.static.yml',
                      'config/locales/static_pages/fr.static.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'config/environments'

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  before :deploy, 'config:install_shared_dir'
  
  after :deploy, 'cleanup:remove_example_configs'
  
#  after :deploy, 'cleanup:bundler'
    
  after :deploy, 'cleanup:restart_passenger'
end

namespace :git do
  after :create_release, 'remove_postgres'
  after :create_release, 'npm_install'
  after :create_release, ':webpack_bundle'
  
  desc 'Remove the postgres dependency from the Gemfile'
  task :remove_postgres do
    on roles(:app), wait: 1 do
      # Comment out the Postgres gem
      execute "cd #{release_path} && mv Gemfile Gemfile.bak"
      execute "cd #{release_path} && cat Gemfile.bak | sed 's/gem \\x27pg\\x27/#gem \\x27pg\\x27/' >> Gemfile"
      execute "cd #{release_path} && bundle install --without test"
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
      execute "cd #{release_path}/lib/assets && npm run bundle -- -p"
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