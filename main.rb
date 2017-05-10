require 'discordrb'
require 'yaml'

client_id = 311535055413575682

bot = Discordrb::Bot.new token: 'MzExNTM1MDU1NDEzNTc1Njgy.C_N7KQ.o7mh1DmD3Ouv9V3sbtFSfH9JaZs', client_id: client_id

puts "https://discordapp.com/api/oauth2/authorize?client_id=#{client_id}&scope=bot&permissions=0"

admins = {
  "137463281676713984" => true,
  "122908555178147840" => true
}


def save_hash(c)
  File.write("countdowns", c.to_yaml)
end

running = true

Signal.trap("INT") do
  puts "Stopping..."
  running = false
end

unconfirmed = {}
countdowns = {}

if File.exists?("countdowns")
  puts "Resuming existing countdowns"
  countdowns = YAML.load_file('countdowns')
end


bot.message(contains: "tokobot del") do |event|
  if admins.has_key?("#{event.user.id}")
    puts "#{event.message}"
    tokens = event.message.content.split(" ")
    if tokens.length == 3
      if !countdowns.has_key?("#{tokens[2]}")
        event.respond("Channel not registered.")
        event.respond("USAGE: tokobot set <channel id> <{{time}}-name-pattern> <end-name> <year> <month> <day> <hour> <minute> <seconds>")
      else
        countdowns.delete("#{tokens[2]}")
        save_hash(countdowns)
        event.respond("Channel removed from counting down.")
      end
    else
      event.respond("USAGE: tokobot del <channel id>")
    end
  end
end

bot.message(contains: "tokobot cancel") do |event|
  if admins.has_key?("#{event.user.id}")
    event.respond("Cancelled.")
    unconfirmed = {}
  end
end

bot.message(contains: "tokobot ok") do |event|
  if admins.has_key?("#{event.user.id}")
    unconfirmed.each do |k,v|
      event.respond("Added to channel #{k}")
      countdowns[k] = v
    end
    save_hash(countdowns)
    unconfirmed = {}
  end
end

bot.message(contains: "tokobot set") do |event|
  if admins.has_key?("#{event.user.id}")
    puts "#{event.message}"
    tokens = event.message.content.split(" ")
    chan_id = tokens[2]
    name_pat = tokens[3]
    end_name = tokens[4]
    year = tokens[5].to_i
    month = tokens[6].to_i
    day = tokens[7].to_i
    hour = tokens[8].to_i
    minute = tokens[9].to_i
    seconds = tokens[10].to_i
    if tokens.length != 11
      event.respond("USAGE: tokobot set <channel id> <{{time}}-name-pattern> <end-name> <year> <month> <day> <hour> <minute> <seconds>")
    else
      begin
        chan = bot.channel(chan_id.to_i)
        if !chan
          event.respond("#{chan_id} channel not found")
        else
          unconfirmed["#{chan_id}"] = { name: name_pat, target: Time.new(year,month,day,hour,minute,seconds).to_i, end_name: end_name }
          event.respond("Will countdown on #{chan.name} in server #{chan.server.name}")
          event.respond("Will look like this: #{unconfirmed["#{chan_id}"][:name].sub("{{time}}", "5-mins")}")
          event.respond("Countdown will go until #{unconfirmed["#{chan_id}"][:target]}")
          event.respond("And then set channel name to '#{unconfirmed["#{chan_id}"][:end_name]}' at the end")
          event.respond("To confirm say 'tokobot ok' otherwise 'tokobot cancel'")
        end
      rescue => e
        event.respond("#{e.message}")
      end
    end

  end
end

bot.run :async

#countdowns["311538191205138432"] = { name: "{{time}}-until-something-happens", target: Time.new(2017,5,10,1,55,0), end_name: "meow" }

def make_pretty_string(amount, str)
  if amount == 1
    "#{amount}-#{str}"
  else
    "#{amount}-#{str}s"
  end
end

loop do
  countdowns.each do |channel_id, info|
    chan = bot.channel("#{channel_id}")
    if info[:target] > Time.now.to_i

      difference = info[:target] - Time.now.to_i
      prettystring = "#{difference}s"

      month = 60 * 60 * 24 * 30
      week = 60 * 60 * 24 * 7
      day = 60 * 60 * 24
      hour = 60 * 60
      minute = 60

      if difference > month
        #months 
        prettystring = make_pretty_string(difference/month, "month")
      elsif difference > week
        #weeks
        prettystring = make_pretty_string(difference/week, "week")
      elsif difference > day
        #day
        prettystring = make_pretty_string(difference/day, "day")
      elsif difference > hour
        #hours
        prettystring = make_pretty_string(difference/hour, "hr")
      elsif difference > minute
        #minutes
        prettystring = make_pretty_string(difference/minute, "min")
      end

      mmo = info[:name].sub("{{time}}", "#{prettystring}")

      puts "#{difference} -> #{mmo}"
      chan.name = info[:name].sub("{{time}}", "#{prettystring}")
    else

      puts "#{info[:end_name]}"
      chan.name = "#{info[:end_name]}"
    end
  end


  sleep(1)
  break if !running


end

bot.stop
