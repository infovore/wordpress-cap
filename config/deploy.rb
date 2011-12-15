require 'erubis'
set :application, "example"
set :repository,  "git@github.com:user/repo.git"
set :scm, :git
set :deploy_to, "/var/www/example.com"

set :deploy_via, :remote_cache
set :copy_exclude, [".git", ".DS_Store", ".gitignore", ".gitmodules"]

server "example.com", :app

namespace :example do
  task :symlink_wordpress, :roles => :app do
    run "ln -nfs #{shared_path}/uploads #{release_path}/wp-content/uploads"
    run "ln -nfs #{shared_path}/wp-config.php #{release_path}/wp-config.php"
  end

  task :symlink_hyper_cache, :roles => :app do
    run "ln -nfs #{shared_path}/advanced-cache.php #{release_path}/wp-content/advanced-cache.php"
    run "ln -nfs #{shared_path}/cache #{release_path}/wp-content/cache"
  end

  task :symlink_legacy_files, :roles => :app do
    run "for f in $(ls -d #{shared_path}/legacy/*); do ln -s $f #{release_path}; done"
  end

  task :write_advanced_cache_template, :roles => :app do
    advanced_cache_template = File.read("wp-content/advanced-cache.php.erb")
    template = Erubis::Eruby.new(advanced_cache_template)
    output =  template.result(:cache_path=> "#{release_path}/wp-content/cache/hyper-cache/")

    put output, "#{release_path}/wp-content/advanced-cache.php"
  end
end

after "deploy:symlink", "example:symlink_wordpress"
after "deploy:symlink", "example:symlink_hyper_cache"
after "deploy:symlink", "example:symlink_legacy_files"
after "deploy", "example:write_advanced_cache_template"
