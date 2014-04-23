class CreateToroJobs < ActiveRecord::Migration
  def self.up
    Toro::Database.up
  end

  def self.down
    Toro::Database.down
  end
end
