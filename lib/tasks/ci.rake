desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'wagon:bundle:update',
             'db:migrate',
             'ci:setup:rspec',
             'spec:requests', # run request specs first to get coverage from spec
             'spec',
             'wagon:test']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear',
                    'wagon:bundle:update',
                    'db:migrate',
                    'erd',
                    'ci:setup:rspec',
                    'spec:requests', # run request specs first to get coverage from spec
                    'spec',
                    'wagon:test',
                    'brakeman',
                    #'qa' # stack level too deep on jenkins :(
                    ]
end

desc "Add column annotations to active records"
task :annotate do
  sh 'annotate -p before'
end

desc "Run brakeman"
task :brakeman do
  # some files seem to cause brakeman to hang. ignore them
  ignores = %w(app/views/people_filters/_form.html.haml
               app/models/mailing_list.rb)
  begin
    Timeout.timeout(120) do
      sh "brakeman -o brakeman-output.tabs --skip-files #{ignores.join(',')}"
    end
  rescue Timeout::Error => e
    puts "\nBrakeman took too long. Aborting."
  end
end

desc "Run quality analysis"
task :qa do
  # do not fail if we find issues
  sh 'rails_best_practices -x config,db -f html --vendor .' rescue nil
  true
end

namespace :erd do
  task :options => :customize
  task :customize do
    ENV['attributes']  ||= 'content,inheritance,foreign_keys,timestamps'
    ENV['indirect']    ||= 'false'
    ENV['orientation'] ||= 'vertical'
    ENV['notation']    ||= 'uml'
    ENV['filename']    ||= 'doc/models'
    ENV['filetype']    ||= 'png'
  end
end

if Rake::Task.task_defined?('spec:requests') # only if current environment knows rspec
  Rake::Task['spec:requests'].actions.clear
  namespace :spec do
    RSpec::Core::RakeTask.new(:requests => 'db:test:prepare') do |t|
      # include phantomjs binary in path
      ENV['PATH'] += File::PATH_SEPARATOR + File.join(File.dirname(__FILE__), '..', '..', "script")
      t.pattern = "./spec/requests/**/*_spec.rb"
      t.spec_opts = "--tag type:request"
    end

    RSpec::Core::RakeTask.new(:performance => 'db:test:prepare') do |t|
      t.pattern = "./spec/performance/**/*_spec.rb"
      t.spec_opts = "--tag performance:true"
    end

    [:domain, :regressions, :decorators].each do |dir|
      RSpec::Core::RakeTask.new(dir => 'db:test:prepare') do |t|
        t.pattern = "./spec/#{dir}/**/*_spec.rb"
      end
    end
  end
end

desc "Load the mysql database configuration for the following tasks"
task :mysql do
  ENV['RAILS_DB_ADAPTER']  = 'mysql2'
  ENV['RAILS_DB_NAME']     = 'jubla_test'
  ENV['RAILS_DB_PASSWORD'] = 'root'
  ENV['RAILS_DB_SOCKET']   = '/var/run/mysqld/mysqld.sock'
end

namespace :jubla do
  desc "Print all groups, roles and permissions"
  task :permissions => :environment do
    Role::TypeList.new(Group.root_types.first).each do |layer, groups|
      puts layer
      groups.each do |group, roles|
        puts '  ' + group
        roles.each do |r|
          puts "    #{r.model_name.human}: #{r.permissions.inspect}"
        end
      end
    end
  end

  desc "Print all abilities"
  task :abilities => :environment do
    Ability.abilities.each do |subject_class, permissions|
      permissions.each do |permission, actions|
        actions.each do |action, condition|
          puts "#{permission.to_s.ljust(18)}\t#{subject_class.to_s.ljust(23)}\t#{action.to_s.ljust(25)}\t#{condition}"
        end
      end
    end
  end
end
