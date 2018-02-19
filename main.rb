require 'discordrb'
require 'yaml'

def client_id 
  ENV["CLIENT_ID"]
end

def client_token
  ENV["CLIENT_TOKEN"]
end

def admin_list 
  ENV["ADMIN_LIST"]
end

@bot = nil

@usage_str = "USAGE: tokobot set <channel id> <{{time}}-name-pattern> <end-name> <year> <month> <day> <hour> <minute> <seconds> [start <year> <month> <day> <hour> <minute> <seconds>] [name]"

puts "https://discordapp.com/api/oauth2/authorize?client_id=#{client_id}&scope=bot&permissions=0"

@admins = admin_list.split(",").map{|x| [x,true]}.to_h

def save_hash(c)
  File.write("countdowns", c.to_yaml)
end

running = true
Signal.trap("INT") do
  if running == false
    exit(1)
  end
  puts "Stopping..."
  running = false

end

@unconfirmed = {}
@countdowns = []

if File.exists?("countdowns")
  @countdowns = YAML.load_file('countdowns')
  puts "Resuming existing countdowns #{@countdowns.count}"
end

def start_bot!(client_id)
  @bot = Discordrb::Bot.new token: client_token, client_id: client_id

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
          puts e
          exit(1)
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
    begin
      @bot.stop
    rescue => e
    end
    puts "Bot not running. Starting up."
    start_bot!(client_id)
  end

end

def make_pretty_string(amount, str)
  if amount == 1
    "#{amount}-#{str}"
  else
    "#{amount}-#{str}s"
  end
end

loop do
  ensure_bot!(client_id)

  now = Time.now.getlocal('+09:00')
  @countdowns.each do |channel_id, info|
    begin
      chan = @bot.channel("#{channel_id}")

      target_time = Time.at(info[:target]).getlocal('+09:00')

      if now.to_i < info[:target] && info[:start] < now.to_i

        difference = info[:target] - now.to_i
        prettystring = "#{difference}s"

        month = 60 * 60 * 24 * 30
        week = 60 * 60 * 24 * 7
        day = 60 * 60 * 24
        hour = 60 * 60
        minute = 60

        month_diff = (target_time.year * 12 + target_time.month) - (now.year * 12 + now.month)
        day_diff = (target_time.to_date - now.to_date).to_i

        if month_diff > 1
          #months 
          prettystring = make_pretty_string(month_diff, "month")
        elsif day_diff > 3
          #day
          prettystring = make_pretty_string(day_diff, "day")
        elsif difference > hour
          #hours
          prettystring = make_pretty_string((difference/hour.to_f).ceil, "hr")
        elsif difference > minute
          #minutes
          prettystring = make_pretty_string((difference/minute.to_f).ceil, "min")
        end

        mmo = info[:name].sub("{{time}}", "#{prettystring}")

        new_chan_name = info[:name].sub("{{time}}", "#{prettystring}")
        if chan.name != new_chan_name || now.sec == 0
          puts "(#{chan.id}) #{difference} M#{month_diff} D#{day_diff} -> #{mmo}"
          chan.name = new_chan_name
        end


      elsif info[:target] < now.to_i && now.to_i < info[:target] + 10
        puts "#{info[:end_name]}"
        chan.name = "#{info[:end_name]}"
      end
    rescue => e
      puts e
      exit(1)
    end
  end

  sleep(0.5)
  break if !running


end

@bot.stop
