EndoBot
=======

The EndoBot is a simple jabber chat listener written in Ruby.
It listens to the specified channel and writes all the messages in the output file.
We use a daily scrum report in the chat that looks like this:

    1. Yesterday
    2. Today
    3. Impediments
    4. Need Help
    5. Sparetime
    

Run it via "ruby EndoBot.rb <jabberId> <password> <channel> <outputfile>"

ToDo: 

Group messages in this format:
Date, Name
Yesterday: 
Today:
Impediments:
Help:
Sparetime: