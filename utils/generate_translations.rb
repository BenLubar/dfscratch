#/usr/bin/env ruby -w

require 'set'

$random = Random.new 127552

def generate_markov words
	m = Hash.new do |hash, key|
		hash[key] = Hash.new 0
	end

	words.each do |word|
		prev = ['', '']
		word.each_char do |c|
			m[prev][c] += 1
			prev = [prev[1], c]
		end
		m[prev][''] += 1
	end

	m
end

def compute_markov markov
	s = ''
	prev = ''
	current = markov[['', '']]
	loop do
		n = 0
		current.each_value do |i|
			n += i
		end
		n = $random.rand(0...n)
		current.each do |k, i|
			n -= i
			if n < 0
				s << k
				current = markov[[prev, k]]
				prev = k
				break
			end
		end
		return s if prev == ''
	end
end

markov = {}

# from Wikipedia, <https://simple.wikipedia.org/wiki/Potato>
markov[:english] = generate_markov %w(
a potato is a type of vegetable the scientific name of the potato plant is solanum tuberosum it contains a lot of starch and other carbohydrates it is a small plant with large leaves the part of the potato that people eat is a tuber that grows under the ground it usually has a brown or pink skin and is white or yellow inside if it gets light on it the tuber turns green and will be poisonous

the potato is from the high and cool areas of the andes of peru it began to be grown as a food crop more than seven thousand years ago when the europeans came to south america in the fifteen hundreds they took the potato back to europe it took nearly two hundred years for the potato to become a widely grown crop in the seventeen eighties the farmers in ireland began growing potatoes because they grew well in the poor soils they also have most of the vitamins that people need to survive the irish became so dependent on the potato that when the crop failed in eighteen forty five there was a famine and many people starved to death

the potato plant is now grown in many different parts of the world captain william bligh planted potatoes on bruny island tasmania in seventeen ninety two in australia they are now the largest vegetable crop

there are now many different types of potato these have names such as:
yukon gold developed in canada
norgleam
yellow finn
bismark
coliban
pontiac
sequoia
desiree cream colored flesh red skin
bintje

scientists in germany have used genetic engineering to make a potato called the amflora which could be grown to make starch for making other things in factories

the potato is not very good to eat unless it is cooked people cook potatoes by boiling baking roasting or frying them french fries or chips are potatoes cut into long pieces and fried until they are soft potato chips often called crisps are potatoes cut into very thin round pieces and fried until they are hard
)

# from La Recluse, <http://www.gutenberg.org/ebooks/17661>
markov[:french] = generate_markov %w(
vers cinq heures gaston de pradelle était toujours debout tenant
lui-même la barre aveuglé par la rafale trempé par les paquets
de mer cherchant vainement à pénétrer ce mur de ténèbres qui
s'interposait entre lui et l'infini

rien jusque-là n'avait entamé ni son énergie ni son courage
son coeur ne battait pas plus vite aucune pâleur n'était montée à
son front

mais il est des limites à la force humaine depuis quelques
minutes il sentait la fatigue envahir ses membres et redoutait
vaguement quelque défaillance il se raidissait cependant bien
résolu à mourir entier à son poste mais déjà une sueur moite
mouillait ses tempes un voile glissait sur ses yeux à deux ou
trois reprises ses doigts se crispèrent comme affolés sur le
métal de la barre

il était perdu

tout à coup un cri s'échappa de ses lèvres un immense soupir de
soulagement souleva sa poitrine et ses regards subitement
illuminés de deux lueurs fulgurantes s'attachèrent avec une
fixité farouche vers un coin du ciel
)

# transliterated from Tribute to Michael Hart, <http://www.gutenberg.org/ebooks/43007>
markov[:arabic] = generate_markov %w(
msa' ywm alrab'e mn tmwz 'eam hyn kan 'ea'edaan ala byth mn mshahdh hfl llal'eab alnaryh bmnasbh 'eyd alastqlal, sh'er baljw'e fmr 'ela mhl llbqalh whnak ahdwh m'e kys mshtryath nskhh mn e'elan alastqlal alshhyr wbdlaan mn an ytsfhh thm ylqyh fy rkn ma aw yd'eh ala janb alktb walmjlat alakhra kma yf'el alakhrwn, fkr bma ymkn an ysn'eh bh balastfadh mn almnhh almqdmh alyh lastkhdam shbkh aljam'eh knw'e mn rd aljmyl b'eml shy' mfyd llnas fqrr an ytb'e ala'elan wywz'eh alktrwnyaan wtb'e alns balf'el wlm ykn dlk balamr alywmy alshl aldy yqwm bh albshr alan mlyarat almrat hyth la nzam tshghyl mthl wndwz wla bramj mryhh mthl alawfs wghyrh lqd kant 'emlyh td'ea thwyl alns ala syghh rqmyh aw shy'eaan mn hda alqbyl wla yqwm bha la almkhtswn! almhm anh arad b'ed tb'e dlk ale'elan an yrslh ala
)

words = Set.new

File.read('../raw/objects/language_symbols_halfling.txt').scan(/\[S_WORD:([^:\[\]]+)\]/) do |word|
	words.add word[0]
end

markov.each do |language, m|
	generated = Set.new

	while generated.size < words.size
		generated.add compute_markov m
	end

	# This one is a bit complicated: it makes a mapping between real and fake words of the
	# same relative length, ignoring _VERB, _RACE, _FRUIT, etc.
	generated = Hash[words.to_a.sort_by{|w| w.gsub(/_[^_]+$/, '').size}.zip(generated.to_a.sort_by(&:size))]

	open "../raw/objects/language_GENERATED_#{language}.txt", "w:CP437" do |f|
		f.puts "language_GENERATED_#{language}"
		f.puts
		f.puts '$' + 'Id$'
		f.puts
		f.puts "[OBJECTS:LANGUAGE]"
		f.puts
		f.puts "[TRANSLATION:GENERATED_#{language.upcase}]"
		generated.each do |k, v|
			f.puts "\t[T_WORD:#{k}:#{v}]"
		end
	end
end
