module Lita
  module Handlers
    class Envy < Handler

      route /\Astarted using env ([A-Za-z0-9_]+)\Z/,  :start_using_environment, help:  { "started using env [ENV ID]"  => "Mark environment as in use by you"}, command: true
      route /\Astopped using env ([A-Za-z0-9_]+)\Z/,  :stop_using_environment, help:  { "stopped using env [ENV ID]"  => "Mark environment as available"}, command: true

      def start_using_environment(response)
        env_id = response.matches.first.first
        redis.hset(['environments', env_id].join(':'), 'user', response.user.name)
        response.reply('ok')
      end

      def stop_using_environment(response)
        env_id = response.matches.first.first
        redis.hset(['environments', env_id].join(':'), 'user', nil)
        response.reply('ok')
      end

      Lita.register_handler(self)
    end
  end
end
