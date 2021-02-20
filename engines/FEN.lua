
require("math")
local http = require("socket.http")
local lunajson = require("lunajson")

local board = {}
board.fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

local function move()

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
    print (sum)
    for i = 1,#moves do
        print(moves[i]["san"], moves[i]["total"])
        if moves[i]["total"] > r then
            --print("info string", sum)
            return "bestmove "..moves[i]["uci"]
        else
            r = r - moves[i]["total"]
        end
    end
end

function database()
    --[[ Function to return values from json body ]]--
    --[[ turn board.fen into http valid link ]]--
    rep = "https://explorer.lichess.ovh/lichess?variant=standard&speeds[]=bullet&speeds[]=blitz&speeds[]=rapid&speeds[]=classical&ratings[]=1600&ratings[]=1800&ratings[]=2000&ratings[]=2200&ratings[]=2500&fen="..string.gsub(board.fen, "%s+", "%%20").."&play=e4e5"
    print(rep)
    res = http.request(rep)
    res_parsed = lunajson.decode(res)
    local moves = res_parsed["moves"]
    return moves
    -- return all valid moves and their popularity in a table
end

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

--FEN("e2e4")
--FEN("c7c5")
--FEN("b1c3")
--FEN("d7d6")
move()
