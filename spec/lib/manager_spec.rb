require 'spec_helper'

describe Toro::Manager do
  describe '.new' do
    it 'creates N processors' do
      concurrency = 5
      manager = Toro::Manager.new(concurrency: concurrency)
      manager.ready.length.should == concurrency
    end
  end

  describe '#start' do
    it 'performs N dispatches' do
      concurrency = 5
      manager = Toro::Manager.new(concurrency: concurrency)
      manager.bare_object.should_receive(:dispatch).exactly(concurrency).times
      manager.start
      manager.stop
    end
  end

  describe '#assign' do
    it 'assigns a job to a processor' do
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      manager = Toro::Manager.new(concurrency: 5)
      manager.assign(job)
      manager.busy.length.should == 1
      manager.stop
    end
  end

  describe '#stop' do
    it 'shuts down' do
      manager = Toro::Manager.new(concurrency: 5)
      manager.stop
      manager.busy.length.should == 0
      manager.ready.length.should == 0
    end
  end

  describe '#processor_complete' do
    it 'returns the processor to the ready pool' do
      manager = Toro::Manager.new(concurrency: 5)
      initial_ready_length = manager.ready.length
      processor = manager.ready.pop
      manager.busy << processor
      manager.processor_complete(processor)
      manager.busy.length.should == 0
      manager.ready.length.should == initial_ready_length
      manager.stop
    end
  end

  describe '#requeue' do
    it "requeues the process's running jobs" do
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'running',
        started_by: Toro.process_identity,
        started_at: Time.now
      )
      manager = Toro::Manager.new
      manager.requeue
      job_should_have_attributes(Toro::Job.first, {
        status: 'queued',
        started_by: nil,
        started_at: nil
      })
    end
  end
end
