require "spec_helper"

describe Lita::Handlers::Envy, lita_handler: true do

  describe 'routing' do

    it { is_expected.to route_command("started using env ENV123").to(:start_using_environment)  }
    it { is_expected.to route_command("stopped using env ENV123").to(:stop_using_environment)  }

  end

  describe 'start using environment' do

    it "should mark environment as in use" do
      carl = Lita::User.create(123, name: "Carl")
      send_command('started using env ENV123', :as => carl)
      expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Carl")
    end

    it "should confirm" do
      send_command('started using env ENV123')
      expect(replies.first).to eq("ok")
    end

  end

  describe 'stop using environment' do

    it "should mark environment as available" do
      subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      send_command('stopped using env ENV123')
      expect(subject.redis.hget('environments:ENV123', 'user')).to be_empty
    end

    it "should confirm" do
      send_command('stopped using env ENV123')
      expect(replies.first).to eq("ok")
    end

  end

end
