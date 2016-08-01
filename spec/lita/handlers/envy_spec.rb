require "spec_helper"

describe Lita::Handlers::Envy, lita_handler: true do

  describe 'routing' do

    it { is_expected.to route_command("started using env ENV123").to(:start_using_environment)  }

  end

  describe 'start using environment' do

    it "should record environment usage" do
      carl = Lita::User.create(123, name: "Carl")
      send_command('started using env ENV123', :as => carl)
      expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Carl")
    end

    it "should confirm" do
      carl = Lita::User.create(123, name: "Carl")
      send_command('started using env ENV123', :as => carl)
      expect(replies.first).to eq("ok")
    end

  end

end
