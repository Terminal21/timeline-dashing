#! /usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'date'

MAX_DAYS_OVERDUE = -5
MAX_DAYS_AWAY = 40

# Fetch the website
def fetch_html()
  website = Nokogiri::HTML(open('https://eigenbaukombinat.de/'))
  return website
end

# Generate a random color name
def gen_color()
  random = Random.new

  colorname = Array.new(9)
  colorname = [ 'red', 'blue', 'lightblue', 'pink', 'gold', 'white', 'yellow', 'green', 'lightgreen',  'orange', 'grey', 'black' ]

  return colorname[random.rand(9)]
end

# Print out the yml event list
def print_event_yml()
  # Parse the event container <aside><div><p>...</p></div></aside>
  # to get the orga dates and names
  doc = fetch_html()
  doc.xpath('//aside//div//p').each do |events_chunk|

    # Split array in cohensive elements at once
    elements = events_chunk.content.split(/\,\ |\.\ |\n/)

    # Puts warning
    elements_yml = "# Do not edit this list manually, it will be overwritten\n"
    elements_yml = elements_yml + "# in a couple of hours anyway!\n\n"

    elements_yml = elements_yml + "events:\n"
    i = 0

    until i >= elements.length do
      if i != nil and elements[i +3] != nil then
        # Puts all event names out of elements
        elements_yml = elements_yml + "  - name: \"" + elements[i + 3] + "\"\n"
      end
      if i != nil then
        # Puts all event dates out of elements
        puts elements[i + 2] + ":" + elements[i + 1]
        begin
          elements_yml = elements_yml + Date.new(2018,elements[i + 2].to_i,elements[i + 1].to_i).strftime("    date: \"%b %d, %Y\"\n")
        rescue ArgumentError
        end
      end
      if i != nil then
        # Puts all event background colors
        elements_yml = elements_yml + "    background: \"" + gen_color() + "\"\n"
      end
      i += 4;
    end
    return elements_yml
  end
end

# !! Altered to fetch all actual events directly from the website !!
#config_file = File.dirname(File.expand_path(__FILE__)) + '/../timeline_data.yml'
config_file = print_event_yml()

SCHEDULER.every '6h', :first_in => 0 do |job|
  #config = YAML::load(File.open(config_file))
  config = YAML::load(config_file)
  unless config["events"].nil?
    events =  Array.new
    today = Date.today
    no_event_today = true
    config["events"].each do |event|
      days_away = (Date.parse(event["date"]) - today).to_i
      if (days_away >= 0) && (days_away <= MAX_DAYS_AWAY) 
        events << {
          name: event["name"],
          date: event["date"],
          background: event["background"]
        }
      elsif (days_away < 0) && (days_away >= MAX_DAYS_OVERDUE)
        events << {
          name: event["name"],
          date: event["date"],
          background: event["background"],
          opacity: 0.5
        }
      end

      no_event_today = false if days_away == 0
    end

    if no_event_today
      events << {
        name: "TODAY",
        date: today.strftime('%a %d %b %Y'),
        background: "gold"
      }
    end

    send_event("a_timeline", {events: events})
  else
    puts "No events found :("
  end
end
