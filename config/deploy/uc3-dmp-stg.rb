set :application, 'DMPTool'
set :repo_url, 'https://github.com/CDLUC3/dmptool.git'

set :server_host, ENV["SERVER_HOST"] || 'uc3-dmp-stg.cdlib.org'
server fetch(:server_host), user: 'dmp', roles: %w{web app db}

set :deploy_to, '/dmp/apps/dmp'
set :share_to, 'dmp/apps/dmp/shared'

# Define the location of the private configuration repo
set :config_branch, 'master'

set :rails_env, 'production'

namespace :deploy do
  namespace :symlink do
    after :linked_files, 'swap_in_stage'
    after :linked_dirs, 'set_log_level'

    # We run stage in Rails production mode so change the 'production:' portions of the database.yml
    # and secrets.yml to 'live:' and then change 'stage:' to 'production:'
    # This MUST run before db:migrate!!!
    desc "Swap in Stage server database/secrets configs and production.rb"
    task :swap_in_stage do
      on roles(:app), wait: 1 do
        execute "cd #{release_path}/config && cp database.yml database-stg.yml && cp secrets.yml secrets-stg.yml"
        execute "cd #{release_path}/config && rm database.yml && rm secrets.yml"
        execute "cd #{release_path}/config && cat database-stg.yml | sed 's/production:/live:/g' > database2.yml"
        execute "cd #{release_path}/config && cat database2.yml | sed 's/stage:/production:/g' > database.yml"
        execute "cd #{release_path}/config && cat secrets-stg.yml | sed 's/production:/live:/g' > secrets2.yml"
        execute "cd #{release_path}/config && cat secrets2.yml | sed 's/stage:/production:/g' > secrets.yml"
        execute "cd #{release_path}/config && rm database-stg.yml && rm secrets-stg.yml"
        execute "cd #{release_path}/config && rm database2.yml && rm secrets2.yml"
      end
    end

    desc "Set the log level to debug for stage"
    task :set_log_level do
      on roles(:app), wait: 1 do
        execute "cd #{release_path}/config/environments && cp production.rb production.rb.bak"
        execute "cd #{release_path}/config/environments && cat production.rb.bak | sed 's/config.log_level = :warn/config.log_level = :debug/g' > production.rb"
      end
    end
  end
end
