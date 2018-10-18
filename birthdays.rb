require "yaml"
require "active_support/duration"

orignames = {
	143964260593172480 => "seiyuu",
	143382005990555648 => "muse",
	137595269633146880 => "aqours",
	314746494634950676 => "nijigasaki-school-idol-club"
}

birthdays = [
	[143964260593172480, "hbd-kussun"  ,  2,  1],
	[143964260593172480, "hbd-pile"    ,  5,  2],
	[143964260593172480, "hbd-shikaco" ,  5, 19],
	[143964260593172480, "hbd-mimorin" ,  6, 28],
	[143964260593172480, "hbd-nanjo"   ,  7, 12],
	[143964260593172480, "hbd-ucchi-and-ainya",  7, 23],
	[143964260593172480, "hbd-rippi"   , 10, 26],
	[143964260593172480, "hbd-emitsun" , 12, 10],
	[143964260593172480, "hbd-soramaru", 12, 26],

	[143964260593172480, "hbd-arisha"  ,  2,  5],
	[143964260593172480, "hbd-anchan"  ,  2,  7],
	[143964260593172480, "hbd-aiai"    ,  2, 19],
	[143964260593172480, "hbd-rikyako" ,  8,  8],
	[143964260593172480, "hbd-shuka"   ,  8, 16],
	[143964260593172480, "hbd-kinchan" ,  9, 25],
	[143964260593172480, "hbd-aikyan"  , 10, 23],
	[143964260593172480, "hbd-suwawa"  , 11,  2],

	[143382005990555648, "hbd-hanayo"  ,  1, 17],
	[143382005990555648, "hbd-umi"     ,  3, 15],
	[143382005990555648, "hbd-maki"    ,  4, 19],
	[143382005990555648, "hbd-nozomi"  ,  6,  9],
	[143382005990555648, "hbd-nico"    ,  7, 22],
	[143382005990555648, "hbd-honoka"  ,  8,  3],
	[143382005990555648, "hbd-kotori"  ,  9, 12],
	[143382005990555648, "hbd-eli"     , 10, 21],
	[143382005990555648, "hbd-rin"     , 11,  1],

	[137595269633146880, "hbd-dia"     ,  1,  1],
	[137595269633146880, "hbd-kanan"   ,  2, 10],
	[137595269633146880, "hbd-zuramaru",  3,  4],
	[137595269633146880, "hbd-you"     ,  4, 17],
	[137595269633146880, "hbd-mari"    ,  6, 13],
	[137595269633146880, "hbd-yohane"  ,  7, 13],
	[137595269633146880, "hbd-chika"   ,  8,  1],
	[137595269633146880, "hbd-riko"    ,  9, 19],
	[137595269633146880, "hbd-ruby"    ,  9, 21],

	[143964260593172480, "hbd-miyutan" ,  1, 31],
	[143964260593172480, "hbd-mayuchi" ,  4, 17],
	[143964260593172480, "hbd-kaorin"  ,  4, 25],
	[143964260593172480, "hbd-agupon"  ,  5,  2],
	[143964260593172480, "hbd-nacchan" ,  9,  7],
	[143964260593172480, "hbd-chunrun" ,  9, 20],
	[143964260593172480, "hbd-tanaka"  , 10,  6],
	[143964260593172480, "hbd-akarin"  , 10, 16],
	[143964260593172480, "hbd-tomoriru", 12, 22],

	[314746494634950676, "hbd-kasukasu",  1, 23],
	[314746494634950676, "hbd-emma"    ,  2,  5],
	[314746494634950676, "hbd-ayumu"   ,  3,  1],
	[314746494634950676, "hbd-shizuku" ,  4,  3],
	[314746494634950676, "hbd-ai"      ,  5, 30],
	[314746494634950676, "hbd-karin"   ,  6, 29],
	[314746494634950676, "hbd-setsuna" ,  8,  8],
	[314746494634950676, "hbd-rina"    , 11, 13],
	[314746494634950676, "hbd-kanata"  , 12, 16],
	
	[137595269633146880, "hbd-sarah"   ,  5,  4],
	[137595269633146880, "hbd-leah"    , 12, 12],
	[143964260593172480, "hbd-asamin"  ,  2, 12],
	[143964260593172480, "hbd-hinahina", 12, 23]
]

res = []

[2018, 2019, 2020].each do |year|

	birthdays.each do |chan, x, month, day|
		if Time.new(year, month, day, 0, 0, 0).to_i 
			res << ["#{chan}", {
				name: x,
				target: ( Time.new(year, month, day, 0, 0, 0) ).to_i + 60 * 60 * 24,
				end_name: orignames[chan],
				start: Time.new(year, month, day, 0, 0, 0).to_i,
				countdown_name: "#{x}-#{year}"
			}]
			
		end
	end
end

File.write("result", res.to_yaml)
