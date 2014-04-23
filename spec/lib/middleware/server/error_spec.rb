require 'spec_helper'

describe Toro::Middleware::Server::Error do
  describe '#call' do
    it 'sets a failed status for exceptions' do
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'FailingWorker',
        args: [],
        status: 'queued'
      )
      processor = Toro::Processor.new(Toro::Manager.new)
      processor.process(job)
      job.status.should == 'failed'
      job.finished_at.should be_within(1).of(Time.now)
    end
  end
end
