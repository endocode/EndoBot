require 'spec_helper'

describe Report do
  before :each do
      @report = Report.new("today", "user")
  end
  
  describe "#set_message" do
      it "sets the messages inside of the report" do
        @report.set_message("1. did something")
        @report.set_message("2. will do something")
        @report.set_message("3. nope")
        @report.set_message("4. maybe")
        @report.set_message("5. never")
        
        @report.date.should eql "today"
        @report.yesterday.should eql "did something"
        @report.today.should eql "will do something"
        @report.impediments.should eql "nope"
        @report.help.should eql "maybe"
        @report.sparetime.should eql "never"
      end
      
      it "gets the messages in the wrong order and sets them inside of the report" do
        @report.set_message("2. will do something")
        @report.set_message("5. never")
        @report.set_message("1. did something")
        @report.set_message("3. nope")
        @report.set_message("4. maybe")
        
        @report.date.should eql "today"
        @report.yesterday.should eql "did something"
        @report.today.should eql "will do something"
        @report.impediments.should eql "nope"
        @report.help.should eql "maybe"
        @report.sparetime.should eql "never"
      end
  end
  
  describe "#correct_user" do
    it "checks if this is the user's report" do
      @report.correct_user("user").should eql true
    end
  end
  
  describe "#set_message_for_user" do
    it "sets the message if its the user's report" do
      @report.set_message_for_user("2. will do something", "user")
      @report.today.should eql "will do something"
    end
  end
  
  describe "#print_report" do
    it "prints the report to the console" do
      #@report.print_report
    end
  end
  
  describe "create reports for different users" do
    it "creates 2 reports" do
      @report1 = Report.new("today", "user1")
      @report2 = Report.new("today", "user2")
      @report1.should be_an_instance_of Report
      @report2.should be_an_instance_of Report
      
      @reports = []
      @reports << @report1
      @reports << @report2
      
      @reports.length.should eql 2
    end
    
    
    
  end

end