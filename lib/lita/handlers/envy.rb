module Lita
  module Handlers
    class Envy < Handler

      route /\Astarted using env ([A-Za-z0-9_]+)\Z/,  :start_using_environment, help:  { "started using env [ENV ID]"  => "Mark environment as in use by you"}, command: true
      route /\Astopped using env ([A-Za-z0-9_]+)\Z/,  :stop_using_environment, help:  { "stopped using env [ENV ID]"  => "Mark environment as available"}, command: true
      route /\Aenvironments\Z/,                       :list_environments, help:  { "environments"  => "List environments"}, command: true
      route /\Aremove env ([A-Za-z0-9_]+)\Z/,         :remove_environment, help:  { "remove env [ENV ID]"  => "Remove environment"}, command: true
      route /\Awrestle env ([A-Za-z0-9_]+) from (.*)\Z/, :wrestle_environment_from_user, help:  { "wrestle env [ENV ID] from [USER]"  => "Mark environment as in use by you, even though it is currently in use by another user"}, command: true

      def start_using_environment(response)
        env_id = response.matches.first.first
        current_user = redis.hget(['environments', env_id].join(':'), 'user')
        if current_user.nil?
          redis.hset(['environments', env_id].join(':'), 'user', response.user.name)
          response.reply('ok')
        elsif current_user == response.user.name
          response.reply("You are already using #{env_id}")
        else
          response.reply("Sorry, #{env_id} is currently in use by #{current_user}")
        end
      end

      def stop_using_environment(response)
        env_id = response.matches.first.first
        redis.hset(['environments', env_id].join(':'), 'user', nil)
        response.reply('ok')
      end

      def list_environments(response)
        lines = []
        redis.keys('environments:*').sort.each do |key|
          env_id = key.split(':').last
          user = redis.hget(key, 'user')
          line = env_id
          line += " (#{user})" unless user.empty?
          lines << line
        end
        response.reply(lines.join("\n"))
      end

      def remove_environment(response)
        env_id = response.matches.first.first
        redis.del(['environments', env_id].join(':'))
        response.reply('ok')
      end

      def wrestle_environment_from_user(response)
        env_id, specified_user = response.matches.first
        current_user = redis.hget(['environments', env_id].join(':'), 'user')
        if specified_user == current_user
          redis.hset(['environments', env_id].join(':'), 'user', response.user.name)
          response.reply('ok')
        elsif current_user.nil? or current_user.empty?
          response.reply("Sorry, #{env_id} is not currently in use")
        elsif current_user == response.user.name
          response.reply("You are already using #{env_id}")
        else
          response.reply("Sorry, #{env_id} is currently in use by #{current_user}, not #{specified_user}")
        end
      end

      Lita.register_handler(self)
    end
  end
end
