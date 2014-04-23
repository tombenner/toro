require 'spec_helper'

describe Toro::Middleware::Server::Retry do
  describe '#call' do
    it 'sets the error properties' do
      now = Time.now.utc
      Time.stub(:now) { now }
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'RetriedFailingWorker',
        args: [],
        status: 'queued'
      )
      processor = Toro::Processor.new(Toro::Manager.new)
      processor.process(job)
      job.status.should == 'scheduled'
      job.scheduled_at.should == now + 1.minute
      job.properties['retry:errors'].length.should == 1
      job.properties['retry:errors'].first.should start_with('RetriedFailingWorker::Error')
    end

    it "doesn't set the error properties for workers that aren't retried" do
      now = Time.now.utc
      Time.stub(:now) { now }
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'FailingWorker',
        args: [],
        status: 'queued'
      )
      processor = Toro::Processor.new(Toro::Manager.new)
      processor.process(job)
      job.status.should_not == 'scheduled'
      job.scheduled_at.should be_nil
      job.properties['retry:errors'].should be_nil
    end
  end
end
