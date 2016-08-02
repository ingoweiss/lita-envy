require "spec_helper"

describe Lita::Handlers::Envy, lita_handler: true do

  describe 'Routing' do

    it { is_expected.to route_command("started using env ENV123").to(:start_using_environment)  }
    it { is_expected.to route_command("stopped using env ENV123").to(:stop_using_environment)  }
    it { is_expected.to route_command("environments").to(:list_environments)  }
    it { is_expected.to route_command("remove env ENV123").to(:remove_environment)  }
    it { is_expected.to route_command("wrestle env ENV123 from Alicia").to(:wrestle_environment_from_user)  }

  end

  describe 'User claiming environment' do

    context "when environment is available" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', '')
      end

      it "should mark environment as in use by user" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('started using env ENV123', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Carl")
      end

      it "should reply with confirmation" do
        send_command('started using env ENV123')
        expect(replies.first).to eq("ok")
      end

    end

    context "when environment is unknown to bot" do

      before(:each) do
        subject.redis.del('environments:ENV123')
      end

      it "should mark environment as in use by user" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('started using env ENV123', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Carl")
      end

      it "should reply with confirmation" do
        send_command('started using env ENV123')
        expect(replies.first).to eq("ok")
      end

    end

    context "when environment is in use by another user" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      end

      it "should leave the environment untouched" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('started using env ENV123', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Alicia")
      end

      it "should reply with notification" do
        subject.redis.hset('environments:ENV123', 'user', 'Alicia')
        carl = Lita::User.create(123, name: "Carl")
        send_command('started using env ENV123', :as => carl)
        expect(replies.first).to eq("Sorry, ENV123 is currently in use by Alicia")
      end

    end

    context "when environment is already in use by user" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', 'Carl')
      end

      it "should leave the environment untouched" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('started using env ENV123', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Carl")
      end

      it "should reply with notification" do
        subject.redis.hset('environments:ENV123', 'user', 'Carl')
        carl = Lita::User.create(123, name: "Carl")
        send_command('started using env ENV123', :as => carl)
        expect(replies.first).to eq("You are already using ENV123")
      end

    end

  end

  describe 'User releasing environment' do

    context "when environment is in use by user" do

      before(:each) do
        subject.redis.hset('environments:ENV234', 'user', 'Alicia')
      end

      it "should mark environment as available" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(subject.redis.hget('environments:ENV234', 'user')).to be_empty
      end

      it "should reply with confirmation" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(replies.first).to eq("ok")
      end

    end

    context "when environment is in use by another user" do

      before(:each) do
        subject.redis.hset('environments:ENV234', 'user', 'Carl')
      end

      it "should leave the environment untouched" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(subject.redis.hget('environments:ENV234', 'user')).to eq('Carl')
      end

      it "should reply with notification" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(replies.first).to eq("You are not currently using ENV234 (Carl is)")
      end

    end

    context "when environment is not in use" do

      before(:each) do
        subject.redis.hset('environments:ENV234', 'user', '')
      end

      it "should leave the environment untouched" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(subject.redis.hget('environments:ENV234', 'user')).to eq('')
      end

      it "should reply with notification" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(replies.first).to eq("You are not currently using ENV234")
      end

    end

    context "when environment is unknown to bot" do

      before(:each) do
        subject.redis.del('environments:ENV234')
      end

      it "should leave the environment untouched" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(subject.redis.hget('environments:ENV234', 'user')).to be_nil
      end

      it "should reply with notification" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('stopped using env ENV234', :as => alicia)
        expect(replies.first).to eq("You are not currently using ENV234")
      end

    end

  end

  describe 'User listing environments' do

    it "should list environments" do
      subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      subject.redis.hset('environments:ENV234', 'user', 'Carl')
      subject.redis.hset('environments:ENV345', 'user', '')
      send_command('environments')
      expect(replies.first.split("\n")).to eq([
        "ENV123 (Alicia)",
        "ENV234 (Carl)",
        "ENV345"
      ])
    end

  end

  describe 'User removing environment' do

    context "when environment is available" do

      before(:each) do
        subject.redis.hset('environments:ENV345', 'user', '')
      end

      it "should remove environments" do
        send_command('remove env ENV345')
        expect(subject.redis.keys).to_not include('environments:ENV345')
      end

      it "should confirm" do
        send_command('remove env ENV345')
        expect(replies.first).to eq("ok")
      end

    end

    context "when environment is unknown to bot" do

      before(:each) do
        subject.redis.del('environments:ENV345')
      end

      it "should reply with notification" do
        send_command('remove env ENV345')
        expect(replies.first).to eq("I do not know about environment ENV345")
      end

    end

    context "when environment is in use by another user" do

      before(:each) do
        subject.redis.hset('environments:ENV345', 'user', 'Carl')
      end

      it "should leave the environment untouched" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('remove env ENV345', :as => alicia)
        expect(subject.redis.hget('environments:ENV345', 'user')).to eq('Carl')
      end

      it "should reply with notification" do
        send_command('remove env ENV345')
        expect(replies.first).to eq("Sorry, ENV345 is currently in use by Carl")
      end

    end

    context "when environment is in use by user" do

      before(:each) do
        subject.redis.hset('environments:ENV345', 'user', 'Alicia')
      end

      it "should leave the environment untouched" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('remove env ENV345', :as => alicia)
        expect(subject.redis.hget('environments:ENV345', 'user')).to eq('Alicia')
      end

      it "should reply with notification" do
        alicia = Lita::User.create(123, name: "Alicia")
        send_command('remove env ENV345', :as => alicia)
        expect(replies.first).to eq("You are currently using ENV345")
      end

    end

  end

  describe 'User claiming environment from other user' do

    context "when environment is currently in use by specified user" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      end

      it "should mark environment as in use" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('wrestle env ENV123 from Alicia', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Carl")
      end

      it "should reply with confirmation" do
        send_command('wrestle env ENV123 from Alicia')
        expect(replies.first).to eq("ok")
      end

    end

    context "when environment is currently in use by a user other than the specified one" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', 'Alicia')
      end

      it "should leave the environment untouched" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('wrestle env ENV123 from Ben', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq("Alicia")
      end

      it "should reply with notification" do
        send_command('wrestle env ENV123 from Ben')
        expect(replies.first).to eq("Sorry, ENV123 is currently in use by Alicia, not Ben")
      end

    end

    context "when environment is not currently in use" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', nil)
      end

      it "should leave the environment untouched" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('wrestle env ENV123 from Ben', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to be_empty
      end

      it "should reply with notification" do
        send_command('wrestle env ENV123 from Ben')
        expect(replies.first).to eq("Sorry, ENV123 is not currently in use")
      end

    end

    context "when environment is already marked as in use by requesting user" do

      before(:each) do
        subject.redis.hset('environments:ENV123', 'user', 'Carl')
      end

      it "should leave the environment untouched" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('wrestle env ENV123 from Ben', :as => carl)
        expect(subject.redis.hget('environments:ENV123', 'user')).to eq('Carl')
      end

      it "should reply with notification" do
        carl = Lita::User.create(123, name: "Carl")
        send_command('wrestle env ENV123 from Ben', :as => carl)
        expect(replies.first).to eq("You are already using ENV123")
      end

    end

  end

end
