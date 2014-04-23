task :environment

namespace :toro do
  desc "Start a new worker for the (default or $QUEUE) queue"
  task :start  => :environment do
    cli = Toro::CLI.new
    cli.run
  end

  desc "Setup Toro tables and functions in database"
  task :up => :environment do
    Toro::Database.up
  end

  desc "Remove Toro tables and functions from database."
  task :down => :environment do
    Toro::Database.down
  end
end
