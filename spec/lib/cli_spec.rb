require 'spec_helper'

describe Toro::CLI do
  describe '.new' do
    it 'sets the default options' do
      cli = Toro::CLI.new(['toro:work'])
      cli.options.should == {}
    end

    it 'sets the queue option' do
      cli = Toro::CLI.new(['toro:work', '-q', 'queue1'])
      cli.options.should include(queues: ['queue1'])
    end

    it 'sets the concurrency option' do
      cli = Toro::CLI.new(['toro:work', '-c', '5'])
      cli.options.should include(concurrency: 5)
    end

    it 'sets multiple options' do
      cli = Toro::CLI.new(['toro:work', '-q', 'queue1', '-q', 'queue2', '-c', '5'])
      cli.options.should include(
        queues: ['queue1', 'queue2'],
        concurrency: 5
      )
    end
  end
end
