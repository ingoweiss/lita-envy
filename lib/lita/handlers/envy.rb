module Lita
  module Handlers
    class Envy < Handler

      route /\Astarted using env ([A-Za-z0-9_]+)\Z/,  :start_using_environment, help:  { "started using env [ENV ID]"  => "Notifies bot that you started using environment"}, command: true

      def start_using_environment(response)
        env_id = response.matches.first.first
        redis.hset(['environments', env_id].join(':'), 'user', response.user.name)
        response.reply('ok')
      end

      Lita.register_handler(self)
    end
  end
end
