require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/muc'

class EndoBot
  
    include Jabber
    Jabber::debug = true
    attr_accessor :jid, :password, :channel, :file

    def initialize
        self.jid = ARGV[0]
        self.password = ARGV[1]
        self.channel = ARGV[2]
        self.file = ARGV[3]
        #@jid = jid
        #@jpassword = jpassword
        @client = Client.new(JID::new(jid))
        @client.allow_tls = false
        @client.connect
        @client.auth(password)
        @client.send(Presence.new.set_type(:available))
    end

    def read_messages
        time = Time.now.asctime
        @room = Jabber::MUC::MUCClient.new(@client)
        @room.join(Jabber::JID.new(channel + @client.jid.node))

        loop do
            @room.add_message_callback do |msg|
              File.open(file, 'a+') do |f2|
                from = msg.from.to_s
                from.slice! channel
                f2.puts "#{time.to_s}, #{from}: #{msg.body}"
              end  
            end
            add_join_callback do |msg|
              #puts msg
            end
        end
    end

    def send_message to,message
        msg = Message::new(to,message)
        msg.type = :chat
        @client.send(msg)
    end
    
    def write_to_file content
      File.open(file, 'a+') do |f2|  
        f2.puts content
      end  
    end
end

bot = EndoBot.new()

t1 = Thread.new do
    bot.read_messages
end

# no need for second thread at the moment
#t2 = Thread.new do
    #bot.send_message('sebastian@endocode.com',Random.new.rand(100).to_s)
#end

Thread.list.each { |t| t.join if t != Thread.main }