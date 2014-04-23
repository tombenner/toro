require 'spec_helper'

describe Toro::Processor do
  describe '#process' do
    it 'tells the manager it is done' do
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      manager = Toro::Manager.new
      processor = Toro::Processor.new(manager)
      manager.should_receive(:processor_complete).with(processor)
      processor.process(job)
      sleep 1
    end

    it 'completes a job' do
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      processor = Toro::Processor.new(Toro::Manager.new)
      processor.process(job)

      job.status.should == 'complete'
      job.finished_at.should be_within(1).of(Time.now)
    end
  end
end
