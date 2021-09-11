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

  Net::HTTP.get(uri)
  res = Net::HTTP.get_response(uri)

  res.body
end

def parse(fen, moves)
  table = JSON.parse(database(fen, moves))

  whitemoves = table['white']
  blackmoves = table['black']
  drawmoves  = table['draws']
  total = whitemoves + blackmoves + drawmoves

  movestable = table['moves']

  newtable = []
  movestable.each do |v|
    whitemoves = v['white']
    blackmoves = v['black']
    drawmoves  = v['draws']
    total = whitemoves + blackmoves + drawmoves
    t = [v['uci'], total]
    newtable.push(t)
  end
  newtable
end

def find_total(tbl)
  total = 0
  tbl.each do |v|
    total += v[1]
  end
  total
end

def decide_next_move(fen, moves)
  t = parse(fen, moves)
  total = find_total(t)
  return exit(1) if total < 5

  pivot = rand(total)
  t.each do |v|
    return v[0] if pivot < v[1]

    pivot -= v[1]
  end
end

exit(1) if ARGV.empty?;
print decide_next_move(ARGV[0], ARGV[1])

