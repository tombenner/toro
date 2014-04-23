module Toro
  module Actor
    def self.included(klass)
      klass.__send__(:include, Celluloid)
      klass.__send__(:task_class, Celluloid::TaskThread)
    end
  end
end
