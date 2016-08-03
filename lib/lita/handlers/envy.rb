module Lita
  module Handlers
    class Envy < Handler

      route /\Aclaim ([A-Za-z0-9_]+)\Z/,             :claim_environment, help:  { "claim [ENV ID]"  => "Mark environment as in use by you"}, command: true
      route /\Arelease ([A-Za-z0-9_]+)\Z/,           :release_environment, help:  { "release [ENV ID]"  => "Mark environment as available"}, command: true
      route /\Aenvs\Z/,                              :list_environments, help:  { "envs"  => "List environments"}, command: true
      route /\Aforget ([A-Za-z0-9_]+)\Z/,            :forget_environment, help:  { "forget [ENV ID]"  => "Forget environment"}, command: true
      route /\Awrestle ([A-Za-z0-9_]+) from (.*)\Z/, :claim_used_environment, help:  { "wrestle [ENV ID] from [USER]"  => "Mark environment as in use by you, even though it is currently in use by another user"}, command: true

      config :namespace, :required => true do
        validate do |value|
          "can only contain lowercase letters, numbers and underscores" unless value.match(/\A[a-z0-9_]+\Z/)
        end
      end

      def claim_environment(response)
        env_id = response.matches.first.first
        current_user = redis.hget(key(env_id), 'user')
        if current_user.nil? || current_user.empty?
          redis.hset(key(env_id), 'user', response.user.name)
          response.reply('ok')
        elsif current_user == response.user.name
          response.reply("Hmm, you are already using #{env_id}")
        else
          response.reply("Hmm, #{env_id} is currently in use by #{current_user}")
        end
      end

      def release_environment(response)
        env_id = response.matches.first.first
        current_user = redis.hget(key(env_id), 'user')
        if current_user == response.user.name
          redis.hset(key(env_id), 'user', nil)
          response.reply('ok')
        elsif current_user.nil? || current_user.empty?
          response.reply("Hmm, you are not currently using #{env_id}")
        else
          response.reply("Hmm, you are not currently using #{env_id} (#{current_user} is)")
        end

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

      def forget_environment(response)
        env_id = response.matches.first.first
        current_user = redis.hget(key(env_id), 'user')
        if current_user == response.user.name
          response.reply("Hmm, you are currently using #{env_id}")
        elsif current_user.nil?
          response.reply("Hmm, I do not know about #{env_id}")
        elsif current_user.empty?
          redis.del(key(env_id))
          response.reply('ok')
        else
          response.reply("Hmm, #{env_id} is currently in use by #{current_user}")
        end
      end

      def claim_used_environment(response)
        env_id, specified_user = response.matches.first
        current_user = redis.hget(key(env_id), 'user')
        if specified_user == current_user
          redis.hset(key(env_id), 'user', response.user.name)
          response.reply('ok')
        elsif current_user.nil? or current_user.empty?
          response.reply("Hmm, #{env_id} is not currently in use")
        elsif current_user == response.user.name
          response.reply("Hmm, you are already using #{env_id}")
        else
          response.reply("Hmm, #{env_id} is currently in use by #{current_user}, not #{specified_user}")
        end
      end

      private

      def key(env_id)
        ['environments', config.namespace, env_id].join(':')
      end

      Lita.register_handler(self)
    end
  end
end
