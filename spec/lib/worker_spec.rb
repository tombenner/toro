require 'spec_helper'

describe Toro::Worker do
  describe '.perform_async' do
    it 'creates a job' do
      DefaultQueueWorker.perform_async
      job_should_have_attributes(Toro::Job.first, {
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      })
    end
  end

  describe '.perform_at' do
    it 'schedules a job' do
      scheduled_at = Time.now
      DefaultQueueWorker.perform_at(scheduled_at)
      job_should_have_attributes(Toro::Job.first, {
        status: 'scheduled',
        scheduled_at: scheduled_at
      })
    end
  end

  describe '.perform_in' do
    it 'schedules a job' do
      now = Time.now.utc
      Time.stub(:now) { now }
      interval = 1.minute
      DefaultQueueWorker.perform_in(interval)
      job_should_have_attributes(Toro::Job.first, {
        status: 'scheduled',
        scheduled_at: now + interval
      })
    end
  end

  describe '.normalize_job' do
    it 'names a job' do
      args = ['a', 'b']
      item = {
        args: args,
        queue: 'default'
      }
      NamedWorker.normalize_job(item)[:name].should == NamedWorker.job_name(*args)
    end
  end
end
