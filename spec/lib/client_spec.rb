require 'spec_helper'

describe Toro::Client do
  describe '.create_job' do
    it 'creates a job' do
      attributes = {
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: [],
        status: 'queued'
      }
      Toro::Client.create_job(attributes)
      job_should_have_attributes(Toro::Job.first, attributes)
    end

    it 'sets the status as queued' do
      attributes = {
        queue: 'default',
        class_name: 'DefaultQueueWorker',
        args: []
      }
      Toro::Client.create_job(attributes)
      job_should_have_attributes(Toro::Job.first, { status: 'queued' })
    end
  end
end
