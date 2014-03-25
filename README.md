# EndoBot

[![Build Status](https://api.travis-ci.org/endocode/EndoBot.png)](http://travis-ci.org/endocode/EndoBot)

The Endobot project consists of two simple jabber clients written in
Ruby - EndoReportBot and EndoChiliBot.

## EndoReportBot

The EndoReportBot is a chat listener.  It listens to the specified
channel and writes all the messages in the output file.  We use a
daily scrum report in the chat that looks like this:

    1. What will I do today for the client?
    2. What will I do today for the company?
    3. Impediments/Help needed

## EndoChiliBot

The EndoChiliBot is an Chili activities atom feed poller.  It polls
given feed every 5 minutes and prints changes to specified channel.

## Setup

See the endobotconfig.ini.example file, rename it to endobotconfig.ini
and run main.rb.  Alternatively, you can pass a path to ini file as a
first parameter.

If you want to run only one bot, say EndoReportBot, then just comment
out the section for EndoChiliBot.
