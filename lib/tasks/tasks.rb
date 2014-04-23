task :environment

namespace :toro do
  desc 'Start processing Toro jobs'
  task :start  => :environment do
    cli = Toro::CLI.new
    cli.run
  end

  desc 'Add Toro tables and functions to the database'
  task :up => :environment do
    Toro::Database.up
  end

  desc 'Remove Toro tables and functions from the database'
  task :down => :environment do
    Toro::Database.down
  end
end

task :toro => 'toro:start'
