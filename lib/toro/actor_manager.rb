module Toro
  module ActorManager
    def register_actor(key, proxy)
      actors[key] = proxy
    end

    def actors
      @actors ||= {}
    end
  end
end
