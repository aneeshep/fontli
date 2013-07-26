require 'capistrano/ext/multistage'
require 'new_relic/recipes'
require 'bundler/capistrano'

#############################################################
#	Application
#############################################################

set :application, "typestry"
set :deploy_to, "/data/www/#{application}"
set :rake, "rake"
set :migrate_target, :latest
set :default_stage, "production"
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
  desc "Updating symlinks"
  task :symlink_shared_paths do
    run "rm #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/public/photos #{release_path}/public/photos"
    run "ln -nfs #{shared_path}/public/avatars #{release_path}/public/avatars"
    run "ln -nfs #{shared_path}/public/fonts #{release_path}/public/fonts"
    #run "ln -nfs #{shared_path}/Gemfile.lock #{release_path}/Gemfile.lock"
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

after "deploy:symlink", "deploy:symlink_shared_paths"
