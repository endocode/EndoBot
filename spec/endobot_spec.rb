require 'spec_helper'


describe EndoBot do

  before :each do
      @bot = EndoBot.new()
      @user = Faker::Internet.user_name
      @user2 = Faker::Internet.user_name
      @today = Date.today
      @yesterday = Date.today.prev_day
      @message = "#{rand 1..5}. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}"
      @file = "logs/test_reports.log"
      @message1 = ("1. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message2 = ("2. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message3 = ("3. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message4 = ("4. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message5 = ("5. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
  end

  describe "#create_reports" do
    it "creates the report list" do
      @bot.create_reports(@date, @user, @message, @file)
      @bot.get_reports_length.should eql 1
    end
    it "creates reports for several users" do
      @bot.create_reports(@date, @user, @message, @file)
      @bot.create_reports(@date, @user2, @message, @file)
      @bot.get_reports_length.should eql 2
    end
    it "creates several reports for the same user" do
      @bot.create_reports(@date, @user, @message, @file)
      @bot.create_reports(@date, @user, @message, @file)
      @bot.get_reports_length.should eql 1

      @bot.create_reports(@date, @user2, @message, @file)
      @bot.create_reports(@date, @user2, @message, @file)

      @bot.get_reports_length.should eql 2
    end

    it "creates a complete report and saves it" do
      @bot.create_reports(@today, @user, @message1, @file).should_not == true
      @bot.create_reports(@today, @user, @message2, @file).should_not == true
      @bot.create_reports(@today, @user, @message3, @file).should_not == true
      @bot.create_reports(@today, @user, @message4, @file).should_not == true
      @bot.create_reports(@today, @user, @message5, @file).should == true
      @bot.get_reports_length.should eql 1

      @message1 = ("1. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message2 = ("2. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message3 = ("3. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message4 = ("4. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message5 = ("5. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")

      @bot.create_reports(@today, @user2, @message1, @file).should_not == true
      @bot.create_reports(@today, @user2, @message2, @file).should_not == true
      @bot.create_reports(@today, @user2, @message3, @file).should_not == true
      @bot.create_reports(@today, @user2, @message4, @file).should_not == true
      @bot.create_reports(@today, @user2, @message5, @file).should == true
      @bot.get_reports_length.should eql 2

      File.exists?(@file).should == true
      File.delete(@file)
    end

    it "gets the number of finished reports for today" do
      @bot.create_reports(@today, @user, @message1, @file).should_not == true
      @bot.create_reports(@today, @user, @message2, @file).should_not == true
      @bot.create_reports(@today, @user, @message3, @file).should_not == true
      @bot.create_reports(@today, @user, @message4, @file).should_not == true
      @bot.create_reports(@today, @user, @message5, @file).should == true
      @bot.get_reports_length.should eql 1

      @bot.create_reports(@today, @user2, @message1, @file).should_not == true
      @bot.create_reports(@today, @user2, @message2, @file).should_not == true
      @bot.get_reports_length.should eql 2

      @bot.create_reports(@yesterday, @user2, @message1, @file).should_not == true
      @bot.create_reports(@yesterday, @user2, @message2, @file).should_not == true

      @message1 = ("1. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message2 = ("2. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message3 = ("3. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message4 = ("4. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")
      @message5 = ("5. #{Faker::Lorem.sentence( rand 1..3 ).chomp '.'}")

      @bot.create_reports(@yesterday, @user, @message1, @file).should_not == true
      @bot.create_reports(@yesterday, @user, @message2, @file).should_not == true
      @bot.create_reports(@yesterday, @user, @message3, @file).should_not == true
      @bot.create_reports(@yesterday, @user, @message4, @file).should_not == true
      @bot.create_reports(@yesterday, @user, @message5, @file).should == true

      @bot.get_todays_reports(@today).should eql 1
      @bot.get_todays_reports(@yesterday).should eql 1

      File.delete("logs/test_reports.log")
    end

    it "gets a list of users that entered reports for today" do
      @bot.create_reports(@today, @user, @message1, @file).should_not == true
      @bot.create_reports(@today, @user, @message2, @file).should_not == true
      @bot.create_reports(@today, @user, @message3, @file).should_not == true
      @bot.create_reports(@today, @user, @message4, @file).should_not == true
      @bot.create_reports(@today, @user, @message5, @file).should == true
      @bot.get_todays_reports(@today).should eql 1
      @bot.get_users_reports(@today).should start_with @user
      File.delete("logs/test_reports.log")
    end

    it "returns true if a user already entered a report" do
      @bot.create_reports(@today, @user, @message1, @file).should_not == true
      @bot.create_reports(@today, @user, @message2, @file).should_not == true
      @bot.create_reports(@today, @user, @message3, @file).should_not == true
      @bot.create_reports(@today, @user, @message4, @file).should_not == true
      @bot.create_reports(@today, @user, @message5, @file).should == true
      @bot.get_todays_reports(@today).should eql 1
      @bot.get_users_reports(@today).should start_with @user
      @bot.user_has_report?(@user).should == true
      @bot.user_has_report?(@user2).should == false
      File.delete("logs/test_reports.log")
    end
    it "returns true if a user already entered a report" do
      @bot.create_reports(@today, @user, @message1, @file).should_not == true
      @bot.create_reports(@today, @user, @message2, @file).should_not == true
      @bot.create_reports(@today, @user, @message3, @file).should_not == true
      @bot.create_reports(@today, @user, @message4, @file).should_not == true
      @bot.create_reports(@today, @user, @message5, @file).should == true
      @bot.get_todays_reports(@today).should eql 1
      @bot.clear_reports()
      @bot.get_todays_reports(@today).should eql 0
      @bot.user_has_report?(@user).should eql false
      @bot.user_has_report?(@user2).should eql false
      File.delete("logs/test_reports.log")
    end
  end
end