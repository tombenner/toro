require 'spec_helper'

describe Toro::Middleware::Server::Properties do
  describe '#call' do
    it 'sets job properties' do
      job = Toro::Job.create!(
        queue: 'default',
        class_name: 'PropertiesWorker',
        args: [],
        status: 'queued'
      )
      processor = Toro::Processor.new(Toro::Manager.new)
      processor.process(job)
      job.reload
      job.properties['foo'].should == 'bar'
    end
  end
end
