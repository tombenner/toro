require 'spec_helper'

describe Toro::Fetcher do
  describe '#retrieve' do
    it 'retrieves the first job' do
      fetcher = Toro::Fetcher.new(manager: Toro::Manager.new)
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      retrieved = fetcher.retrieve
      retrieved.id.should == job.id
    end

    it 'only retrieves jobs in its queue' do
      fetcher = Toro::Fetcher.new(manager: Toro::Manager.new)
      Toro::Job.create!(
        queue: 'foo',
        class_name: 'FooQueueWorker',
        args: [],
        status: 'queued'
      )
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      retrieved = fetcher.retrieve
      retrieved.id.should == job.id
    end

    it 'only retrieves queued jobs' do
      fetcher = Toro::Fetcher.new(manager: Toro::Manager.new)
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'complete'
      )
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      retrieved = fetcher.retrieve
      retrieved.id.should == job.id
    end

    it 'retrieves scheduled jobs' do
      fetcher = Toro::Fetcher.new(manager: Toro::Manager.new)
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'scheduled',
        scheduled_at: Time.now - 1.minute
      )
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      retrieved = fetcher.retrieve
      retrieved.id.should == job.id
    end

    it "does not retrieve scheduled jobs that aren't ready yet" do
      fetcher = Toro::Fetcher.new(manager: Toro::Manager.new)
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'scheduled',
        scheduled_at: Time.now + 1.minute
      )
      fetcher.retrieve.should be_nil
    end

    it "sets the running job's attributes" do
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      fetcher = Toro::Fetcher.new(manager: Toro::Manager.new)
      fetcher.retrieve
      job_should_have_attributes(Toro::Job.first, {
        status: 'running',
        started_by: Toro.process_identity
      })
    end
  end
end
