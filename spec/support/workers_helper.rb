class DefaultQueueWorker
  include Toro::Worker

  def perform
  end
end

class FooQueueWorker
  include Toro::Worker
  toro_options queue: 'foo'

  def perform
  end
end

class FailingWorker
  class Error < ::Exception; end
  include Toro::Worker

  def perform
    raise FailingWorker::Error.new('FailingWorker failed!')
  end
end

class RetriedFailingWorker
  class Error < ::Exception; end
  include Toro::Worker
  toro_options retry_interval: 1.minute

  def perform
    raise RetriedFailingWorker::Error.new('RetriedFailingWorker failed!')
  end
end

class NamedWorker
  include Toro::Worker

  def perform
  end

  def self.job_name(arg1, arg2)
    "#{arg1} - #{arg2}"
  end
end

class PropertiesWorker
  include Toro::Worker

  def perform
    {
      job_properties: {
        'foo' => 'bar'
      }
    }
  end
end
