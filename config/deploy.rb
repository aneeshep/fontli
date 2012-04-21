require 'capistrano/ext/multistage'

#############################################################
#	Application
#############################################################

set :application, "typestry"
set :deploy_to, "/data/www/#{application}"
set :rake, "rake"
set :migrate_target, :latest
set :default_stage, "staging"
set :stages, %w(production staging)


#############################################################
#	Settings
#############################################################

ssh_options[:keys] = %w(/home/sathish/.ssh/id_rsa)
set :ssh_options, { :forward_agent => true }
set :keep_releases, 2
set :user, "root"
set :use_sudo, false
default_run_options[:pty] = true
set :compile_assets, (ENV['COMPILE_ASSETS'] == 'true')

#############################################################
#	Git
#############################################################

set :repository,  "git@github.com:Imaginea/fontli.git"
set :repository_cache, "git_cache"
set :deploy_via, :checkout
set :git_shallow_clone, 1
set :scm, :git

#############################################################
#	Passenger
#############################################################

namespace :deploy do
  desc "Compile asets"
  task :assets do
    if compile_assets
      run "cd #{release_path}; bundle exec rake assets:precompile"
    end
  end

  desc "Updating symlinks"
  task :symlink_shared_paths do
    run "rm #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    run "rm #{release_path}/config/admin_creds.yml"
    run "ln -nfs #{shared_path}/config/admin_creds.yml #{release_path}/config/admin_creds.yml"
    run "ln -nfs #{shared_path}/public/assets #{release_path}/public/assets"
    run "ln -nfs #{shared_path}/public/photos #{release_path}/public/photos"
    run "ln -nfs #{shared_path}/public/avatars #{release_path}/public/avatars"
    run "ln -nfs #{shared_path}/public/fonts #{release_path}/public/fonts"
    #run "ln -nfs #{shared_path}/Gemfile.lock #{release_path}/Gemfile.lock"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    #do nothing. This is to avoid restart before callbacks. Task deploy, does a restart
  end
  
  desc "Restarting passenger with restart.txt"
  task :my_restart, :roles => :app, :except => { :no_release => true } do
    run "sudo /etc/init.d/httpd restart"
  end

  desc "Running bundle install"
  task :bundle_install do
    #run "cd #{deploy_to}/current; bundle install;"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
end

namespace :rake do  
  desc "Run a task on a remote server."  
  # run like: cap rake:invoke task=db:populate 
  task :invoke do  
    run("cd #{deploy_to}/current; rake #{ENV['task']} RAILS_ENV=#{rails_env}")  
  end  
end

before "deploy:symlink", "deploy:assets"

after :deploy, "deploy:symlink_shared_paths"
after "deploy:symlink_shared_paths", "deploy:cleanup"
after "deploy:cleanup", "deploy:bundle_install"
after "deploy:bundle_install", "deploy:my_restart"
