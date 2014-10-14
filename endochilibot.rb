require 'open-uri'
require 'rss'
require_relative 'report'
require_relative 'botbase'

class EndoChiliBot < BotBase

  private

  class FeedData
    attr_reader :uri
    attr_accessor :last_updated
    attr_reader :template

    def initialize(uri, date, template, regexp)
      @uri = uri
      @last_updated = date
      @template = template
      @regexp = regexp
    end

    def get_message(author, title, id)
      if title =~ @regexp
        "#{author} #{template} (#{$1} - #{$2}) - #{id}"
      else
        "!@!@!@!@! #{author} (#{title}) !@!@!@!@!"
      end
    end
  end

  def setup_scheduler(scheduler)
    super
    scheduler.every '5m', first_in: '1m' do
      report_chili_activities
    end
  end

  def report_chili_activities
    data_items_to_print = []
    now = DateTime.now
    @feed_data.each do |data|
      data.uri.open do |rss|
        feed = RSS::Parser::parse(rss)
        if feed.updated.content.to_datetime > data.last_updated
          feed.items.each do |item|
            if item.updated.content.to_datetime > data.last_updated
              data_items_to_print << {d: data, i: item}
            end
          end
        end
        data.last_updated = now
      end
    end
    data_items_to_print.sort! { |i1, i2| i1[:i].updated.content <=> i2[:i].updated.content }
    print_data_items(data_items_to_print)
  end

  def print_data_items(data_items)
    log.debug("Got #{data_items.length} items to print.")
    messages = []
    data_items.each do |data_item|
      item = data_item[:i]
      data = data_item[:d]
      author = get_nick_for_user(item.author.email.content.gsub('@endocode.com', ''))
      title = item.title.content
      id = item.id.content
      message = data.get_message(author, title, id)
      unless message.empty?
        messages << message
      end
    end
    message_to_send = messages.join("\n")
    send_message_to_room(message_to_send)
  end

  def section_name
    'endochilibot'
  end

  def get_needed_keys
    super + ['feed', 'key']
  end

  def apply_settings(settings)
    super
    feed = settings['feed']
    key = settings['key']
    @feed_data = generate_feed_data(feed, key)
  end

  def generate_feed_data(feed, key)
    data_stubs = [
                  {
                    q: {show_issues: 1},
                    t: 'changed an issue',
                    r: /(.*) - (.*)/
                  },
#                  {
#                    q: {show_changesets: 1},
#                    t: ' ??? '
#                    r: /\?\?\?/
#                  },
                  {
                    q: {show_documents: 1},
                    t: 'added a document',
                    r: /(.*) - (.*)/
                  },
#                  {
#                    q: {show_files: 1},
#                    t: ' added a file ',
#                    r: /\?\?\?/
#                  },
#                  {
#                    q: {show_messages: 1},
#                    t: ' ??? ',
#                    r: /\?\?\?/
#                  },
                  {
                    q: {show_news: 1},
                    t: ' posted news ',
                    r: /(.*) - (.*)/
                  },
                  {
                    q: {show_time_entries: 1},
                    t: 'added a time entry',
                    r: /^(.*) - \d+\.\d+ hours? \((.*)/
                  },
                  {
                    q: {show_wiki_edits: 1},
                    t: 'edited a wiki',
                    r: /^(.*) - Wiki edit: (.*)$/
                  }
                 ]
    data = []
    now = DateTime.now
    data_stubs.map do |stub|
      uri = URI.parse(feed)
      uri.query = URI.encode_www_form({key: key, set_filter: 1}.merge(stub[:q]))
      FeedData.new(uri, now, stub[:t], stub[:r])
    end
  end

end
