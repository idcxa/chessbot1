#!/usr/bin/env ruby

require 'net/http'
require 'json'

# TODO: don't keep these as globals
fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
moves = ''

def database(fen, moves)
  uri = URI('https://explorer.lichess.ovh/lichess?variant=standard&speeds[]'\
            '=bullet&speeds[]=blitz&speeds[]=rapid&speeds[]=classical&ratings[]'\
            '=1600&ratings[]=1800&ratings[]=2000&ratings[]=2200&ratings[]=2500&moves=50'\
            "&play=#{moves}&fen=#{fen.gsub(' ', '%20')}")

  #Net::HTTP.get(uri)
  Net::HTTP.get_response(uri).body
end

def parse(fen, moves)
  json = JSON.parse(database(fen, moves))['moves']

  movestable = []
  json.each do |v|
    t = [v['uci'], v['white'], v['black'], v['draws']]
    movestable.push(t)
  end
  movestable
end

def find_random(tbl)
  total = 0
  tbl.each do |v|
    total += (v[1] + v[2] + v[3])
  end
  total
  return exit(1) if total < 5

  pivot = rand(total)
  tbl.each do |v|
    sum = v[1] + v[2] + v[3]
    return v[0] if pivot < sum

    pivot -= sum
  end
end

def find_best(tbl, colour)
  bestmove = ''
  bestchance = 0
  count = 0
  top = 10
  
  tbl.each do |v|
    count += 1
    return bestmove if count > top
    total = (v[1] + v[2] + v[3]) 
    break if total < 20
    if colour == 'w' then
      m = v[1]
    else
      m = v[2]
    end
    chance = m / total.to_f
    if chance > bestchance then
      bestmove = v[0]
      bestchance = chance
    end
  end
  return exit(1) if bestmove == ''
  bestmove
end

def decide_next_move(fen, moves)
  if fen == 'startpos' then fen == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" end
  movestable = parse(fen, moves)
  v = fen.gsub(/\s+/m, ' ').strip.split(' ')
  colour = v[1]
  #find_best(movestable, colour)
  find_random(movestable)
end

exit(1) if ARGV.empty?;
print decide_next_move(ARGV[0], ARGV[1])

