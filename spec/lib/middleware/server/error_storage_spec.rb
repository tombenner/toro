require 'spec_helper'

describe Toro::Middleware::Server::ErrorStorage do
  describe '#call' do
    it 'sets the error properties' do
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'FailingWorker',
        args: [],
        status: 'queued'
      )
      processor = Toro::Processor.new(Toro::Manager.new)
      processor.process(job)
      job.properties.should include({
        'error:class' => 'FailingWorker::Error',
        'error:message' => 'FailingWorker failed!'  
      })
      job.properties['error:backtrace'].should be_instance_of(Array)
      job.properties['error:backtrace'].should_not be_empty
    end
  end
end
