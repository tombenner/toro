require 'spec_helper'

describe Toro::Listener do
  class DummyListenerManager
    include Toro::ActorManager

    def stop
      actors[:listener].stop
    end
  end

  describe '#start' do
    it 'notifies the fetcher when a job is created' do
      manager = DummyListenerManager.new
      fetcher = double('fetcher').stub(:notify)
      fetcher.should_receive(:notify)
      listener = Toro::Listener.new(fetcher: fetcher, manager: manager)
      listener.async.start
      # Wait for the listener to start listening
      sleep 0.1
      Toro::Job.create!(
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      )
      manager.stop
      # Wait for the NOTIFY to be received
      sleep 0.1
    end

    it 'notifies the fetcher three times when three jobs are created' do
      manager = DummyListenerManager.new
      fetcher = double('fetcher').stub(:notify)
      fetcher.should_receive(:notify).exactly(3).times
      listener = Toro::Listener.new(fetcher: fetcher, manager: manager)
      listener.async.start
      # Wait for the listener to start listening
      sleep 0.1
      3.times do
        Toro::Job.create!(
          queue: 'default',
          class_name: 'DefaultQueueWorker',
          args: [],
          status: 'queued'
        )
      end
      manager.stop
      # Wait for the NOTIFY to be received
      sleep 0.1
    end

    it "doesn't notify the fetcher when a job in a different queue is created" do
      manager = DummyListenerManager.new
      fetcher = double('fetcher').stub(:notify)
      fetcher.should_not_receive(:notify)
      listener = Toro::Listener.new(fetcher: fetcher, manager: manager)
      listener.async.start
      # Wait for the listener to start listening
      sleep 0.1
      Toro::Job.create!(
        queue: 'foo',
        class_name: 'FooQueueWorker',
        args: [],
        status: 'queued'
      )
      manager.stop
      # Wait for the NOTIFY to be received
      sleep 0.1
    end
  end
end
