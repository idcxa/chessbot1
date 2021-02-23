
--[[
Description of the universal chess interface (UCI)    April 2004
================================================================

* The specification is independent of the operating system. For Windows,
  the engine is a normal exe file, either a console or "real" windows application.

* all communication is done via standard input and output with text commands,

* The engine should boot and wait for input from the GUI,
  the engine should wait for the "isready" or "setoption" command to set up its internal parameters
  as the boot process should be as quick as possible.

* the engine must always be able to process input from stdin, even while thinking.

* all command strings the engine receives will end with '\n',
  also all commands the GUI receives should end with '\n',
  Note: '\n' can be 0x0c or 0x0a0c or any combination depending on your OS.
  If you use Engine und GUI in the same OS this should be no problem if you cummunicate in text mode,
  but be aware of this when for example running a Linux engine in a Windows GUI.

* The engine will always be in forced mode which means it should never start calculating
  or pondering without receiving a "go" command first.

* Before the engine is asked to search on a position, there will always be a position command
  to tell the engine about the current position.

* by default all the opening book handling is done by the GUI,
  but there is an option for the engine to use its own book ("OwnBook" option, see below)

* if the engine or the GUI receives an unknown command or token it should just ignore it and try to
  parse the rest of the string.

* if the engine receives a command which is not supposed to come, for example "stop" when the engine is
  not calculating, it should also just ignore it.
]]--

require("math")
local http = require("socket.http")
local lunajson = require("lunajson")
local FEN = require 'chess.fen'

local board = {}
board.startpos = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
board.fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
board.moves = ""

file = io.open("output.txt", "w+")

local moves = {}

function FEN(move)
    local FEN = {}
    for str in string.gmatch(board.fen, "([^".."%s".."]+)") do
        table.insert(FEN, str)
    end
    local newboard = {}
    for str in string.gmatch(FEN[1], "([^".."/".."]+)") do
        table.insert(newboard, str)
    end

    local FENarr = {}
    for i = 1,8 do
        FENarr[i] = {}
        for j = 1,#newboard[i] do
            c = newboard[i]:sub(j,j)
            if string.match(c, "[1,2,3,4,5,6,7,8]") then
                for k = 1,tonumber(newboard[i]:sub(j,j)) do
                    table.insert(FENarr[i], 1)
                end
            else
                table.insert(FENarr[i], c)
            end
        end
    end

    FENarr[9-tonumber(move:sub(4,4))][string.byte(move:sub(3,3))-96]
    = FENarr[9-tonumber(move:sub(2,2))][string.byte(move:sub(1,1))-96]
    FENarr[9-tonumber(move:sub(2,2))][string.byte(move:sub(1,1))-96] = 1

    for i = 1,8 do
        newboard[i] = ""
        j = 1
        repeat
            n = 0
            if FENarr[i][j] == 1 then
                repeat
                    n = n + 1
                until FENarr[i][j+n] ~= 1
                if j+n == 10 then
                   n = n - 1
                end
                newboard[i] = newboard[i]..(n)
                j = j + n - 1
            else
                newboard[i] = newboard[i]..FENarr[i][j]
            end
            j = j + 1
        until j > 8
    end

    FEN[1] = ""
    for i = 1,8 do
        for j = 1,#newboard[i] do
            FEN[1] = FEN[1]..newboard[i]:sub(j,j)
        end
        if i ~= 8 then
            FEN[1] = FEN[1].."/"
        end
    end
    if FEN[2] == "w" then
        FEN[2] = "b"
    else
        FEN[2] = "w"
        FEN[6] = FEN[6] + 1
    end

    board.fen = ""
    for i = 1,6 do
        board.fen = board.fen..FEN[i].." "
    end
    print(board.fen)
end

function database()
    --[[ Function to return values from json body ]]--
    --[[ turn board.fen into http valid link ]]--
    file:write(board.moves)
    rep = "ttps://explorer.lichess.ovh/lichess?variant=standard&speeds[]=bullet&speeds[]=blitz&speeds[]=rapid&speeds[]=classical&ratings[]=1600&ratings[]=1800&ratings[]=2000&ratings[]=2200&ratings[]=2500&play="..board.moves.."&fen="..string.gsub(board.startpos, "%s+", "%%20")
    print(rep)
    res = http.request(rep)
    res_parsed = lunajson.decode(res)
    local moves = res_parsed["moves"]

    local FEN = {}
    for str in string.gmatch(board.fen, "([^".."%s".."]+)") do
        table.insert(FEN, str)
    end
    local newboard = {}
    for str in string.gmatch(FEN[1], "([^".."/".."]+)") do
        table.insert(newboard, str)
    end

    local FENarr = {}
    for i = 1,8 do
        FENarr[i] = {}
        for j = 1,#newboard[i] do
            c = newboard[i]:sub(j,j)
            if string.match(c, "[1,2,3,4,5,6,7,8]") then
                for k = 1,tonumber(newboard[i]:sub(j,j)) do
                    table.insert(FENarr[i], x)
                end
            else
                table.insert(FENarr[i], c)
            end
        end
    end

    for i = 1,8 do
        for j = 1,8 do
            io.write(FENarr[i][j])
        end
        io.write('\n')
    end


    return moves
    -- return all valid moves and their popularity in a table

end

function move()
    --[[ Function to return a single move based on popularity and interfacing with chess-bot]]--
    moves = database()

    sum = 0
    for i = 1,#moves do
        n = 0
        n = n + moves[i]["white"]
        n = n + moves[i]["draws"]
        n = n + moves[i]["black"]
        table.insert(moves[i], "total")
        moves[i]["total"] = n
        sum = sum + n
    end
    local r = math.random(sum)
    print (r)
    for i = 1,#moves do
        print(moves[i]["san"], moves[i]["total"])
        if moves[i]["total"] > r then
            print("info string", sum)
            file:write(board.fen, "\n")
            file:write("bestmove "..moves[i]["uci"].."\n")
            return "bestmove "..moves[i]["uci"]
        else
            r = r - moves[i]["total"]
        end
    end
end
--io.write("info string fuck\n")
--io.output(file)
--io.write("fuck")

function loop()
    while true do
        local input = io.read("*line\n")
        --print("info string ", input)
        --file:write(input)
        local cmd = {}
        for str in string.gmatch(input, "([^".."%s".."]+)") do
                table.insert(cmd, str)
        end
        file:write("INPUT:", input, "\n")
        if cmd[1] == "uci" then
            print("id name ChessTrainer.lua 0.1")
            print("id author Izzy Cassell")
            file:write("info string id author Izzy Cassell\n")
            io.write("uciok\n")
            print("uciok")
            file:write("uciok\n")
        elseif cmd[1] == "isready" then
            io.write("readyok\n")
            print("readyok\n")
            file:write("readyok\n")
        elseif cmd[1] == "position" then
            if cmd[2] == "startpos" then
                board.fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
                --print("info string ", cmd[4], cmd[5], cmd[6])
                --print("info string ", FEN.fenstr_move(board.fen, cmd[4]))
            end
            if cmd[2] == "fen" then
                board.fen = ""
                for i = 3,#cmd do
                    board.fen = board.fen..cmd[i]
                end
            end
            if cmd[3] == "moves" then
                board.moves = ""
                for i = 4,#cmd do
                    board.moves = board.moves..cmd[i]..","
                    FEN(cmd[i])
                end
                file:write(board.fen, "\n")
                print("info string ", board.fen)
            end
        end
        if cmd[1] == "go" then
            print(move())
        end
        if cmd[1] == "quit" then
            return
        end
        --input = "uci"
    end
end

loop()

