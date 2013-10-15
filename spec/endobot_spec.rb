require 'spec_helper'

describe EndoBot do

  before :each do
      @bot = EndoBot.new()
  end

  describe "#create_reports" do
    it "creates the report list" do
      @bot.create_reports("today", "user1", "1. foobar", "logs/test_reports.log")
      @bot.get_reports_length.should eql 1
    end
    it "creates reports for several users" do
      @bot.create_reports("today", "user1", "1. foobar", "logs/test_reports.log")
      @bot.create_reports("today", "user2", "1. foobar", "logs/test_reports.log")
      @bot.get_reports_length.should eql 2
    end
    it "creates several reports for the same user" do
      @bot.create_reports("today", "user1", "1. foobar", "logs/test_reports.log")
      @bot.create_reports("today", "user1", "2. foobar", "logs/test_reports.log")
      @bot.create_reports("today", "user1", "5. foobar", "logs/test_reports.log")
      @bot.get_reports_length.should eql 1

      @bot.create_reports("today", "user2", "2. foobar", "logs/test_reports.log")
      @bot.create_reports("today", "user2", "3. foobar", "logs/test_reports.log")
      @bot.create_reports("today", "user2", "4. foobar", "logs/test_reports.log")

      @bot.get_reports_length.should eql 2
    end

    it "creates a complete report and saves it" do
      @bot.create_reports("today", "user1", "1. foobar", "logs/test_reports.log").should_not == true
      @bot.create_reports("today", "user1", "2. foobar", "logs/test_reports.log").should_not == true
      @bot.create_reports("today", "user1", "3. foobar", "logs/test_reports.log").should_not == true
      @bot.create_reports("today", "user1", "4. foobar", "logs/test_reports.log").should_not == true
      @bot.create_reports("today", "user1", "5. foobar", "logs/test_reports.log").should == true
      @bot.get_reports_length.should eql 1

      File.exists?("logs/test_reports.log").should == true
      File.delete("logs/test_reports.log")
    end
  end
end