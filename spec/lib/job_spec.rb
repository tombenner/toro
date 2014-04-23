require 'spec_helper'

describe Toro::Job do
  describe '#set_properties' do
    it 'sets the properties' do
      job = Toro::Job.new
      job.set_properties(foo: 'bar')
      job.properties.should == { 'foo' => 'bar' }
    end

    it "doesn't save the job" do
      job = Toro::Job.new
      job.set_properties(foo: 'bar')
      job.new_record?.should be_true
    end
  end
end
