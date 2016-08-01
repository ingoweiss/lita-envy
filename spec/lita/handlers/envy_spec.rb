require "spec_helper"

describe Lita::Handlers::Envy, lita_handler: true do

  describe 'routing' do

    it { is_expected.to route_command("started using env ENV123").to(:start_using_environment)  }
    it { is_expected.to route_command("stopped using env ENV123").to(:stop_using_environment)  }
    it { is_expected.to route_command("environments").to(:list_environments)  }
    it { is_expected.to route_command("remove env ENV123").to(:remove_environment)  }

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

  describe 'list environments' do

    it "should list environments" do
      subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      subject.redis.hset('environments:ENV234', 'user', 'Carl')
      subject.redis.hset('environments:ENV345', 'user', nil)
      send_command('environments')
      expect(replies.first.split("\n")).to eq([
        "ENV123 (Alicia)",
        "ENV234 (Carl)",
        "ENV345"
      ])
    end

  end

  describe 'remove environment' do

    it "should remove environments" do
      subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      send_command('remove env ENV123')
      expect(subject.redis.keys).to_not include('environments:ENV123')
    end

    it "should confirm" do
      send_command('remove env ENV123')
      expect(replies.first).to eq("ok")
    end

  end

end
