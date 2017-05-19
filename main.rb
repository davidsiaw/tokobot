::RBNACL_LIBSODIUM_GEM_LIB_PATH = "#{`pwd`.chomp}/libsodium.dll"  if ENV["_system_name"] == "Cygwin"
require 'discordrb'
require 'yaml'

client_id = 311535055413575682

@bot = nil

@usage_str = "USAGE: tokobot set <channel id> <{{time}}-name-pattern> <end-name> <year> <month> <day> <hour> <minute> <seconds> [start <year> <month> <day> <hour> <minute> <seconds>] [name]"

puts "https://discordapp.com/api/oauth2/authorize?client_id=#{client_id}&scope=bot&permissions=0"

@admins = {
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

@unconfirmed = {}
@countdowns = []

if File.exists?("countdowns")
  puts "Resuming existing countdowns"
  @countdowns = YAML.load_file('countdowns')
end

def start_bot!(client_id)
  @bot = Discordrb::Bot.new token: 'MzExNTM1MDU1NDEzNTc1Njgy.C_N7KQ.o7mh1DmD3Ouv9V3sbtFSfH9JaZs', client_id: client_id

  @bot.message(contains: "tokobot del") do |event|
    if @admins.has_key?("#{event.user.id}")
      puts "#{event.message}"
      tokens = event.message.content.split(" ")
      if tokens.length == 3
        if tokens[2].to_i >= @countdowns.length
          event.respond("No such channel. Please use tokobot list\n#{@usage_str}")
        else
          new_arr = []
          @countdowns.each_with_index {|x,i| new_arr << x if i != tokens[2].to_i }
          @countdowns = new_arr
          save_hash(@countdowns)
          event.respond("Channel removed from counting down.")
        end
      else
        event.respond("USAGE: tokobot del <channel id>")
      end
    end
  end

  @bot.message(contains: "tokobot list") do |event|
    if @admins.has_key?("#{event.user.id}")

      if @countdowns.length == 0
        event.respond("Nothing registered :(")
      else
        @countdowns.each_with_index do |x,i|
          chan = @bot.channel("#{x[0]}")
          event.respond( "#{i}) ##{chan.name} -> From #{Time.at(x[1][:start] || 0).to_datetime} To #{Time.at(x[1][:target]).to_datetime} (#{x[1][:countdown_name]})" );
          sleep(0.5)
        end
      end
    end
  end

  @bot.message(contains: "tokobot cancel") do |event|
    if @admins.has_key?("#{event.user.id}")
      event.respond("Cancelled.")
      @unconfirmed = {}
    end
  end

  @bot.message(contains: "tokobot ok") do |event|
    if @admins.has_key?("#{event.user.id}")
      @unconfirmed.each do |k,v|
        event.respond("Added to channel #{k}")
        @countdowns << [k, v]
      end
      save_hash(@countdowns)
      @unconfirmed = {}
    end
  end

  @bot.message(contains: "tokobot set") do |event|
    if @admins.has_key?("#{event.user.id}")
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

      start_a = tokens[11]

      start_year = tokens[12].to_i
      start_month = tokens[13].to_i
      start_day = tokens[14].to_i
      start_hour = tokens[15].to_i
      start_minute = tokens[16].to_i
      start_seconds = tokens[17].to_i

      countdown_name = tokens[18]

      if tokens.length != 11 && (tokens.length != 18 || tokens[11] != "start") && (tokens.length != 19 || tokens[11] != "start")
        event.respond(@usage_str)
      else
        begin
          chan = @bot.channel(chan_id.to_i)
          if !chan
            event.respond("#{chan_id} channel not found")
          else
            begin
              @unconfirmed["#{chan_id}"] = { 
                name: name_pat, 
                target: Time.new(year,month,day,hour,minute,seconds).to_i, 
                end_name: end_name, 
                start: start_a ? Time.new(start_year,start_month,start_day,start_hour,start_minute,start_seconds).to_i : 0,
                countdown_name: countdown_name
              }

              event.respond("Checking to see if I can change the channel name...")
              oldname = chan.name
              sleep(1)
              chan.name = oldname + "-"
              sleep(1)
              chan.name = oldname
              event.respond(<<-RESPONSE
Will countdown on ##{chan.name} in server #{chan.server.name}
Will look like this: #{@unconfirmed["#{chan_id}"][:name].sub("{{time}}", "5-mins")}
Countdown will go starting from #{Time.at(@unconfirmed["#{chan_id}"][:start])}
Countdown will go until #{Time.at(@unconfirmed["#{chan_id}"][:target])}
And then set channel name to '#{@unconfirmed["#{chan_id}"][:end_name]}' at the end
To confirm say 'tokobot ok' otherwise 'tokobot cancel'
              RESPONSE
            )
              
            rescue => e
              p e
              event.respond("I cannot access the channel. Please give me Manage Channel, Send and Receive Messages permissions on that channel")
              @unconfirmed.delete("#{chan_id}")
            end
          end
        rescue => e
          event.respond("#{e.message}")
        end
      end

    end
  end

  @bot.run :async

end

def ensure_bot!(client_id)

  connected = true
  begin
    connected = @bot.connected?
  rescue => e
    puts e
    connected = false
  end

  if !connected
    puts "Bot not running. Starting up."
    if !@bot
      start_bot!(client_id)
    end
  end

end

#countdowns["311538191205138432"] = { name: "{{time}}-until-something-happens", target: Time.new(2017,5,10,1,55,0), end_name: "meow" }

def make_pretty_string(amount, str)
  if amount == 1
    "#{amount}-#{str}"
  else
    "#{amount}-#{str}s"
  end
end

loop do
  ensure_bot!(client_id)

  begin
    @countdowns.each do |channel_id, info|
      chan = @bot.channel("#{channel_id}")
      if Time.now.to_i < info[:target] && info[:start] < Time.now.to_i

        difference = info[:target] - Time.now.to_i
        prettystring = "#{difference}s"

        month = 60 * 60 * 24 * 30
        week = 60 * 60 * 24 * 7
        day = 60 * 60 * 24
        hour = 60 * 60
        minute = 60

        if difference > month
          #months 
          prettystring = make_pretty_string((difference/month.to_f).ceil, "month")
        elsif difference > week
          #weeks
          prettystring = make_pretty_string((difference/week.to_f).ceil, "week")
        elsif difference > day
          #day
          prettystring = make_pretty_string((difference/day.to_f).ceil, "day")
        elsif difference > hour
          #hours
          prettystring = make_pretty_string((difference/hour.to_f).ceil, "hr")
        elsif difference > minute
          #minutes
          prettystring = make_pretty_string((difference/minute.to_f).ceil, "min")
        end

        mmo = info[:name].sub("{{time}}", "#{prettystring}")

        puts "#{difference} -> #{mmo}"
        chan.name = info[:name].sub("{{time}}", "#{prettystring}")
      elsif info[:target] < Time.now.to_i && Time.now.to_i < info[:target] + 10
        puts "#{info[:end_name]}"
        chan.name = "#{info[:end_name]}"
      end
    end
  rescue
  end

  sleep(0.5)
  break if !running


end

@bot.stop
