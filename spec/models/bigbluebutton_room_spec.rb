# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRoom do
  it "loaded correctly" do
    BigbluebuttonRoom.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { Factory.create(:bigbluebutton_room) }

  it { should belong_to(:server) }
  it { should belong_to(:owner) }
  it { should_not validate_presence_of(:owner_id) }
  it { should_not validate_presence_of(:owner_type) }

  it { should validate_presence_of(:server_id) }
  it { should validate_presence_of(:meetingid) }
  it { should validate_presence_of(:voice_bridge) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:param) }

  it { should be_boolean(:private) }
  it { should be_boolean(:randomize_meetingid) }

  [:name, :server_id, :meetingid, :attendee_password, :moderator_password,
   :welcome_msg, :owner, :server, :private, :logout_url, :dial_number,
   :voice_bridge, :max_participants, :owner_id, :owner_type,
   :randomize_meetingid, :param].
    each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end
  it { should_not allow_mass_assignment_of(:id) }

  it { should validate_uniqueness_of(:meetingid) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_uniqueness_of(:voice_bridge) }
  it { should validate_uniqueness_of(:param) }

  it {
    room = Factory.create(:bigbluebutton_room)
    room.server.should_not be_nil
  }

  it { should ensure_length_of(:meetingid).is_at_least(1).is_at_most(100) }
  it { should ensure_length_of(:name).is_at_least(1).is_at_most(150) }
  it { should ensure_length_of(:attendee_password).is_at_most(16) }
  it { should ensure_length_of(:moderator_password).is_at_most(16) }
  it { should ensure_length_of(:welcome_msg).is_at_most(250) }
  it { should ensure_length_of(:param).is_at_least(3) }

  # attr_accessors
  [:running, :participant_count, :moderator_count, :attendees,
   :has_been_forcibly_ended, :start_time, :end_time, :external].each do |attr|
    it { should respond_to(attr) }
    it { should respond_to("#{attr}=") }
  end

  context ".to_param" do
    it { should respond_to(:to_param) }
    it {
      r = Factory.create(:bigbluebutton_room)
      r.to_param.should be(r.param)
    }
  end

  it { should respond_to(:is_running?) }

  describe "#user_role" do
    let(:room) { Factory.build(:bigbluebutton_room, :moderator_password => "mod", :attendee_password => "att") }
    it { should respond_to(:user_role) }
    it { room.user_role({ :password => room.moderator_password }).should == :moderator }
    it { room.user_role({ :password => room.attendee_password }).should == :attendee }
    it { room.user_role({ :password => "wrong" }).should == nil }
    it { room.user_role({ :password => nil }).should == nil }
    it { room.user_role({ :not_password => "any" }).should == nil }
  end

  describe "#instance_variables_compare" do
    let(:room) { Factory.create(:bigbluebutton_room) }
    let(:room2) { BigbluebuttonRoom.last }
    it { should respond_to(:instance_variables_compare) }
    it { room.instance_variables_compare(room2).should be_empty }
    it "compares instance variables" do
      room2.running = !room.running
      room.instance_variables_compare(room2).should_not be_empty
      room.instance_variables_compare(room2).should include(:@running)
    end
    it "ignores attributes" do
      room2.private = !room.private
      room.instance_variables_compare(room2).should be_empty
    end
  end

  describe "#attr_equal?" do
    before { Factory.create(:bigbluebutton_room) }
    let(:room) { BigbluebuttonRoom.last }
    let(:room2) { BigbluebuttonRoom.last }
    it { should respond_to(:attr_equal?) }
    it { room.attr_equal?(room2).should be_true }
    it "compares instance variables" do
      room2.running = !room.running
      room.attr_equal?(room2).should be_false
    end
    it "compares attributes" do
      room2.private = !room.private
      room.attr_equal?(room2).should be_false
    end
    it "compares objects" do
      room2 = room.clone
      room.attr_equal?(room2).should be_false
    end
  end

  context "initializes" do
    let(:room) { BigbluebuttonRoom.new }

    it "fetched attributes before they are fetched" do
      room.participant_count.should == 0
      room.moderator_count.should == 0
      room.running.should be_false
      room.has_been_forcibly_ended.should be_false
      room.start_time.should be_nil
      room.end_time.should be_nil
      room.attendees.should == []
    end

    context "meetingid" do
      it { room.meetingid.should_not be_nil }
      it {
        b = BigbluebuttonRoom.new(:meetingid => "user defined")
        b.meetingid.should == "user defined"
      }
    end

    context "voice_bridge" do
      it {
        b = BigbluebuttonRoom.new(:voice_bridge => "user defined")
        b.voice_bridge.should == "user defined"
      }
      context "with a random value" do
        it { room.voice_bridge.should_not be_nil }
        it { room.voice_bridge.should =~ /7[0-9]{4}/ }
        it "tries to randomize 10 times if voice_bridge already exists" do
          room = Factory.create(:bigbluebutton_room, :voice_bridge => "70000")
          BigbluebuttonRoom.stub!(:find_by_voice_bridge).and_return(room)
          SecureRandom.should_receive(:random_number).exactly(10).and_return(0000)
          room2 = BigbluebuttonRoom.new # triggers the random_number calls
          room2.voice_bridge.should == "70000"
        end
      end
    end
  end

  context "param format" do
    let(:msg) { I18n.t('bigbluebutton_rails.rooms.errors.param_format') }
    it { should validate_format_of(:param).not_with("123 321").with_message(msg) }
    it { should validate_format_of(:param).not_with("").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab@c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab#c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab$c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ab%c").with_message(msg) }
    it { should validate_format_of(:param).not_with("ábcd").with_message(msg) }
    it { should validate_format_of(:param).not_with("-abc").with_message(msg) }
    it { should validate_format_of(:param).not_with("abc-").with_message(msg) }
    it { should validate_format_of(:param).with("_abc").with_message(msg) }
    it { should validate_format_of(:param).with("abc_").with_message(msg) }
    it { should validate_format_of(:param).with("abc") }
    it { should validate_format_of(:param).with("123") }
    it { should validate_format_of(:param).with("abc-123_d5") }
  end

  context "sets param as the downcased parameterized name if param is" do
    after :each do
      @room.save.should be_true
      @room.param.should == @room.name.downcase.parameterize
    end
    it "nil" do
      @room = Factory.build(:bigbluebutton_room, :param => nil,
                            :name => "-My Name@ _Is Odd_-")
    end
    it "empty" do
      @room = Factory.build(:bigbluebutton_room, :param => "",
                            :name => "-My Name@ _Is Odd_-")
    end
  end

  context "using the api" do
    before { mock_server_and_api }
    let(:room) { Factory.create(:bigbluebutton_room) }

    describe "#fetch_is_running?" do

      it { should respond_to(:fetch_is_running?) }

      it "fetches is_running? when not running" do
        mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(false)
        room.server = mocked_server
        room.fetch_is_running?
        room.running.should == false
        room.is_running?.should == false
      end

      it "fetches is_running? when running" do
        mocked_api.should_receive(:is_meeting_running?).with(room.meetingid).and_return(true)
        room.server = mocked_server
        room.fetch_is_running?
        room.running.should == true
        room.is_running?.should == true
      end

    end

    describe "#fetch_meeting_info" do

      # these hashes should be exactly as returned by bigbluebutton-api-ruby to be sure we are testing it right
      let(:hash_info) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>false, :hasBeenForciblyEnded=>false, :startTime=>nil, :endTime=>nil,
          :participantCount=>0, :moderatorCount=>0, :attendees=>[], :messageKey=>"", :message=>""
        }
      }
      let(:users) {
        [
         {:userID=>"ndw1fnaev0rj", :fullName=>"House M.D.", :role=>:moderator},
         {:userID=>"gn9e22b7ynna", :fullName=>"Dexter Morgan", :role=>:moderator},
         {:userID=>"llzihbndryc3", :fullName=>"Cameron Palmer", :role=>:viewer},
         {:userID=>"rbepbovolsxt", :fullName=>"Trinity", :role=>:viewer}
        ]
      }
      let(:hash_info2) {
        { :returncode=>true, :meetingID=>"test_id", :attendeePW=>"1234", :moderatorPW=>"4321",
          :running=>true, :hasBeenForciblyEnded=>false, :startTime=>DateTime.parse("Wed Apr 06 17:09:57 UTC 2011"),
          :endTime=>nil, :participantCount=>4, :moderatorCount=>2,
          :attendees=>users, :messageKey=>{ }, :message=>{ }
        }
      }

      it { should respond_to(:fetch_meeting_info) }

      it "fetches meeting info when the meeting is not running" do
        mocked_api.should_receive(:get_meeting_info).
          with(room.meetingid, room.moderator_password).and_return(hash_info)
        room.server = mocked_server

        room.fetch_meeting_info
        room.running.should == false
        room.has_been_forcibly_ended.should == false
        room.participant_count.should == 0
        room.moderator_count.should == 0
        room.start_time.should == nil
        room.end_time.should == nil
        room.attendees.should == []
      end

      it "fetches meeting info when the meeting is running" do
        mocked_api.should_receive(:get_meeting_info).
          with(room.meetingid, room.moderator_password).and_return(hash_info2)
        room.server = mocked_server

        room.fetch_meeting_info
        room.running.should == true
        room.has_been_forcibly_ended.should == false
        room.participant_count.should == 4
        room.moderator_count.should == 2
        room.start_time.should == DateTime.parse("Wed Apr 06 17:09:57 UTC 2011")
        room.end_time.should == nil

        users.each do |att|
          attendee = BigbluebuttonAttendee.new
          attendee.from_hash(att)
          room.attendees.should include(attendee)
        end
      end

    end

    describe "#send_end" do

      it { should respond_to(:send_end) }

      it "send end_meeting" do
        mocked_api.should_receive(:end_meeting).with(room.meetingid, room.moderator_password)
        room.server = mocked_server
        room.send_end
      end

    end

    describe "#send_create" do
      let(:attendee_password) { Forgery(:basic).password }
      let(:moderator_password) { Forgery(:basic).password }
      let(:hash_create) {
        {
          :returncode => "SUCCESS", :meetingID => "test_id",
          :attendeePW => attendee_password, :moderatorPW => moderator_password,
          :hasBeenForciblyEnded => "false", :messageKey => {}, :message => {}
        }
      }

      it { should respond_to(:send_create) }

      context "send create_meeting" do

        context "for a stored room" do
          before do
            mocked_api.should_receive(:create_meeting).
              with(room.name, room.meetingid, room.moderator_password,
                   room.attendee_password, room.welcome_msg, room.dial_number,
                   room.logout_url, room.max_participants, room.voice_bridge).
              and_return(hash_create)
            room.server = mocked_server
            room.send_create
          end
          it { room.attendee_password.should be(attendee_password) }
          it { room.moderator_password.should be(moderator_password) }
          it { room.changed?.should be_false }
        end

        context "for a new_record" do
          let(:new_room) { Factory.build(:bigbluebutton_room) }
          before do
            mocked_api.should_receive(:create_meeting).
              with(new_room.name, new_room.meetingid, new_room.moderator_password,
                   new_room.attendee_password, new_room.welcome_msg, new_room.dial_number,
                   new_room.logout_url, new_room.max_participants, new_room.voice_bridge).
              and_return(hash_create)
            new_room.server = mocked_server
            new_room.send_create
          end
          it { new_room.attendee_password.should be(attendee_password) }
          it { new_room.moderator_password.should be(moderator_password) }
          it("do not save the record") { new_room.new_record?.should be_true }
        end

      end

      context "randomizes meetingid" do
        let(:fail_hash) { { :returncode => true, :meetingID => "new id",
            :messageKey => "duplicateWarning" } }
        let(:success_hash) { { :returncode => true, :meetingID => "new id",
            :messageKey => "" } }
        let(:new_id) { "new id" }
        before {
          room.randomize_meetingid = true
          room.server = mocked_server
        }

        it "before calling create" do
          room.should_receive(:random_meetingid).and_return(new_id)
          mocked_api.should_receive(:create_meeting).
            with(room.name, new_id, room.moderator_password,
                 room.attendee_password, room.welcome_msg, room.dial_number,
                 room.logout_url, room.max_participants, room.voice_bridge)
          room.send_create
        end

        it "and tries again on error" do
          # fails twice and them succeds
          room.should_receive(:random_meetingid).exactly(3).times.and_return(new_id)
          mocked_api.should_receive(:create_meeting).
            with(room.name, new_id, room.moderator_password,
                 room.attendee_password, room.welcome_msg, room.dial_number,
                 room.logout_url, room.max_participants, room.voice_bridge).
            twice.
            and_return(fail_hash)
          mocked_api.should_receive(:create_meeting).
            with(room.name, new_id, room.moderator_password,
                 room.attendee_password, room.welcome_msg, room.dial_number,
                 room.logout_url, room.max_participants, room.voice_bridge).
            once.
            and_return(success_hash)
          room.send_create
        end

        it "and limits to 10 tries" do
          room.should_receive(:random_meetingid).exactly(11).times.and_return(new_id)
          mocked_api.should_receive(:create_meeting).
            with(room.name, new_id, room.moderator_password,
                 room.attendee_password, room.welcome_msg, room.dial_number,
                 room.logout_url, room.max_participants, room.voice_bridge).
            exactly(10).times.
            and_return(fail_hash)
          room.send_create
        end
      end

      context "uses #full_logout_url when set" do
        before do
          room.full_logout_url = "full-version-of-logout-url"
          mocked_api.should_receive(:create_meeting).
            with(room.name, room.meetingid, room.moderator_password,
                 room.attendee_password, room.welcome_msg, room.dial_number,
                 "full-version-of-logout-url", room.max_participants, room.voice_bridge).
            and_return(hash_create)
          room.server = mocked_server
        end
        it { room.send_create }
      end

    end

    describe "#join_url" do
      let(:username) { Forgery(:name).full_name }

      it { should respond_to(:join_url) }

      it "with moderator role" do
        mocked_api.should_receive(:join_meeting_url).
          with(room.meetingid, username, room.moderator_password)
        room.server = mocked_server
        room.join_url(username, :moderator)
      end

      it "with attendee role" do
        mocked_api.should_receive(:join_meeting_url).
          with(room.meetingid, username, room.attendee_password)
        room.server = mocked_server
        room.join_url(username, :attendee)
      end

      it "without a role" do
        mocked_api.should_receive(:join_meeting_url).
          with(room.meetingid, username, 'pass')
        room.server = mocked_server
        room.join_url(username, nil, 'pass')
      end
    end

  end

  context "validates passwords" do
    context "for private rooms" do
      let (:room) { Factory.build(:bigbluebutton_room, :private => true) }
      it { room.should_not allow_value('').for(:moderator_password) }
      it { room.should_not allow_value('').for(:attendee_password) }
    end

    context "for public rooms" do
      let (:room) { Factory.build(:bigbluebutton_room, :private => false) }
      it { room.should allow_value('').for(:moderator_password) }
      it { room.should allow_value('').for(:attendee_password) }
    end
  end

  describe "#add_domain_to_logout_url" do
    context "when logout_url has a path only" do
      let(:room) { Factory.create(:bigbluebutton_room, :logout_url => '/only/path') }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should == "http://test.com:80/only/path" }
      it { room.logout_url.should == "/only/path" }
      it { BigbluebuttonRoom.find(room.id).logout_url.should == "/only/path" }
    end

    context "when logout_url has a path and domain" do
      let(:room) { Factory.create(:bigbluebutton_room, :logout_url => 'other.com/only/path') }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should == "http://other.com/only/path" }
      it { room.logout_url.should == "other.com/only/path" }
      it { BigbluebuttonRoom.find(room.id).logout_url.should == "other.com/only/path" }
    end

    context "when logout_url has a path, domain and protocol" do
      let(:room) { Factory.create(:bigbluebutton_room, :logout_url => 'HTTPS://other.com/only/path') }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should == "https://other.com/only/path" }
      it { room.logout_url.should == "HTTPS://other.com/only/path" }
      it { BigbluebuttonRoom.find(room.id).logout_url.should == "HTTPS://other.com/only/path" }
    end

    context "does nothing if logout_url is nil" do
      let(:room) { Factory.create(:bigbluebutton_room, :logout_url => nil) }
      before(:each) { room.add_domain_to_logout_url("HTTP://", "test.com:80") }
      it { room.full_logout_url.should be_nil }
      it { room.logout_url.should be_nil }
      it { BigbluebuttonRoom.find(room.id).logout_url.should be_nil }
    end
  end

  describe "#perform_join" do
    let(:room) { Factory.create(:bigbluebutton_room) }
    let(:user) { Factory.build(:user) }

    context "for an attendee" do
      before { room.should_receive(:fetch_is_running?) }

      context "when the conference is running" do
        before {
          room.should_receive(:is_running?).and_return(true)
          room.should_receive(:join_url).with(user.name, :attendee).
          and_return("http://test.com/attendee/join")
        }
        subject { room.perform_join(user.name, :attendee) }
        it { should == "http://test.com/attendee/join" }
      end

      context "when the conference is not running" do
        before { room.should_receive(:is_running?).and_return(false) }
        subject { room.perform_join(user.name, :attendee) }
        it { should be_nil }
      end
    end

    context "for a moderator" do
      before { room.should_receive(:fetch_is_running?) }

      context "when the conference is running" do
        before {
          room.should_receive(:is_running?).and_return(true)
          room.should_receive(:join_url).with(user.name, :moderator).
          and_return("http://test.com/moderator/join")
        }
        subject { room.perform_join(user.name, :moderator) }
        it { should == "http://test.com/moderator/join" }
      end

      context "when the conference is not running" do
        before {
          room.should_receive(:is_running?).and_return(false)
          room.should_receive(:send_create)
          room.should_receive(:join_url).with(user.name, :moderator).
          and_return("http://test.com/moderator/join")
        }
        subject { room.perform_join(user.name, :moderator) }
        it { should == "http://test.com/moderator/join" }
      end

      context "when the arg 'request' is informed" do
        let(:request) { stub(ActionController::Request) }
        before {
          request.stub!(:protocol).and_return("HTTP://")
          request.stub!(:host_with_port).and_return("test.com:80")
          room.should_receive(:add_domain_to_logout_url).with("HTTP://", "test.com:80")
          room.should_receive(:is_running?).and_return(true)
          room.should_receive(:join_url).with(user.name, :moderator).
          and_return("http://test.com/moderator/join")
        }
        subject { room.perform_join(user.name, :moderator, request) }
        it { should == "http://test.com/moderator/join" }
      end

    end

  end

  describe "#full_logout_url" do
    subject { BigbluebuttonRoom.new }
    it { should respond_to(:full_logout_url) }
    it { should respond_to(:"full_logout_url=") }
  end

end
