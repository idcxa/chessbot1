
require("math")
require "fun" ()
local http = require("socket.http")
local lunajson = require("lunajson")

local board = {}
board.startpos = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
board.fen = "rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2"
--board.fen = board.startpos
board.moves = ""

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
        --print(moves[i]["san"], moves[i]["total"])
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
    --print(board.moves)
    rep = "https://explorer.lichess.ovh/lichess?variant=standard&speeds[]=bullet&speeds[]=blitz&speeds[]=rapid&speeds[]=classical&ratings[]=1600&ratings[]=1800&ratings[]=2000&ratings[]=2200&ratings[]=2500&play="..board.moves.."&fen="..string.gsub(board.fen, "%s+", "%%20")
    res = http.request(rep)
    --print(res)
    res_parsed = lunajson.decode(res)
    local moves = res_parsed["moves"]

    print(board.fen)


    -- put FEN into modifiable array
    -- split board.fen by spaces
    local FEN = {}
    for str in string.gmatch(board.fen, "([^".."%s".."]+)") do
        table.insert(FEN, str)
    end
    -- split FEN[1] by "/"
    local newboard = {}
    for str in string.gmatch(FEN[1], "([^".."/".."]+)") do
        table.insert(newboard, str)
    end
    -- put result into array
    local FENarr = {}
    for i = 1,8 do
        FENarr[i] = {}
        for j = 1,#newboard[i] do
            c = newboard[i]:sub(j,j)
            if string.match(c, "[1,2,3,4,5,6,7,8]") then
                for k = 1,tonumber(newboard[i]:sub(j,j)) do
                    table.insert(FENarr[i], ".")
                end
            else
                table.insert(FENarr[i], c)
            end
        end
    end

    local function empty_array()
        local t = {}
        for i = 1,8 do
            t[i] = {}
            for j = 1,8 do
                t[i][j] = nil
            end
        end
        return t
    end

    local attackers = 0

    -- initialise attacked squares array
    local attacked = empty_array()

    local checking = empty_array()

    -- moves for rook
    local function rook(x,y)

        local rook = empty_array()
        local empty = empty_array()

        local xbreak = false
        local ybreak = false

        local local_attacked = empty_array()

        for i = 1,8 do
            if not xbreak then
                rook[x][i] = "x"
            end
            if (string.match(FENarr[x][i], "[r,n,b,q,p,k,R,N,B,Q,P]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[x][i], "[r,n,b,q,p,R,N,B,Q,P,K]") and string.match(FENarr[x][y], "[R,Q]")) then
                if i < y then
                    for _it,v in range(0,i-1) do
                        rook[x][v] = nil
                    end
                    for _it,v in range(0,y) do
                        checking[x][v] = nil
                    end
                elseif i > y then
                    xbreak = true
                end
                if ((string.match(FENarr[x][i], "[r,n,b,q,p,k]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[x][i], "[R,N,B,Q,P,K]") and string.match(FENarr[x][y], "[R,Q]"))) and i ~= y and rook[x][i] ~= nil then
                    rook[x][i] = nil
                    if attacked[x][i] == nil and i < y then
                        for j = 1,i-1 do
                            local_attacked[x][j] = nil
                        end

                    end
                    local_attacked[x][i] = true
                end
            end
            if (string.match(FENarr[x][i], "[K]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[x][i], "[k]") and string.match(FENarr[x][y], "[R,Q]")) and rook[x][i] ~= nil then
                if i < y then
                    for _it,v in range(i,y) do
                        checking[x][v] = "x"
                    end
                elseif i > y then
                    for _it,v in range(y,i) do
                        checking[x][v] = "x"
                    end
                end
            end

            if not ybreak then
                rook[i][y] = "x"
            end
            if (string.match(FENarr[i][y], "[r,n,b,q,p,k,R,N,B,Q,P]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[i][y], "[r,n,b,q,p,R,N,B,Q,P,K]") and string.match(FENarr[x][y], "[R,Q]")) then
                if i < x then
                    for _it,v in range(0,i-1) do
                        if v ~= 0 then
                            rook[v][y] = nil
                        end
                    end
                    for _it,v in range(1,x) do
                        checking[v][y] = nil
                    end
                elseif i > x then
                    ybreak = true
                end
                if ((string.match(FENarr[i][y], "[r,n,b,q,p,k]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[i][y], "[R,N,B,Q,P,K]") and string.match(FENarr[x][y], "[R,Q]"))) and i ~= x and rook[i][y] ~= nil then
                    rook[i][y] = nil
                    if attacked[i][y] == nil and i < x then
                        for j = 1,i-1 do
                            local_attacked[j][y] = nil
                        end

                    end
                    local_attacked[i][y] = true
                end
            end
            if (string.match(FENarr[i][y], "[K]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[i][y], "[k]") and string.match(FENarr[x][y], "[R,Q]")) and rook[i][y] ~= nil then
                if i < y then
                    for _it,v in range(i,y) do
                        checking[x][v] = "x"
                    end
                elseif i > y then
                    for _it,v in range(y,i) do
                        checking[x][v] = "x"
                    end
                end
            end
        end
        for i = 1,8 do
            for j = 1,8 do
                if local_attacked[i][j] ~= nil then
                    attacked[i][j] = true
                end
            end
        end
        rook[x][y] = nil
        return rook
    end

    --moves for bishop
    local function bishop(x,y)
        local bishop = empty_array()
        bishop [x] = {}
        for i = 1,8 do
            for j = 1,8 do
                if i + y == j + x or i == -j + x + y then
                    bishop[i][j] = "x"
                end
            end
        end
        for i = 1,8 do
            for j = 1,8 do
                if string.match(FENarr[i][j], "[r,n,b,q,p,R,N,B,Q,P]") or (string.match(FENarr[i][j], "[k]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[K]") and FEN[2] == "w") then
                    if i + y == j + x then
                        if (string.match(FENarr[x][i], "[r,n,b,q,p]") and string.match(FENarr[x][y], "[b,q]")) or (string.match(FENarr[x][i], "[R,N,B,Q,P]") and string.match(FENarr[x][y], "[B,Q]")) then

                            bishop[i][j] = nil
                            attacked[i][j] = "x"
                            attacked[x][y] = nil
                        end
                        if i < x then
                            for k = 1,8 do
                                for p = 1,j-1 do
                                    if k + y == p + x then
                                        bishop[k][p] = nil
                                    end
                                end
                            end
                        elseif i > x then
                            for k = 1,8 do
                                for p = j+1,8 do
                                    if k + y == p + x then
                                        bishop[k][p] = nil
                                    end
                                end
                            end
                        end
                    elseif  i - x == y - j then
                        if (string.match(FENarr[x][i], "[r,n,b,q,p]") and string.match(FENarr[x][y], "[b,q]")) or (string.match(FENarr[x][i], "[R,N,B,Q,P]") and string.match(FENarr[x][y], "[B,Q]")) then
                            bishop[i][j] = nil
                            attacked[i][j] = "x"
                            attacked[x][y] = nil
                        end
                        if i < x then
                            for k = 1,8 do
                                for p = j+1,8 do
                                    if k - x == y - p then
                                        bishop[k][p] = nil
                                    end
                                end
                            end
                        elseif i > x then
                            for k = 1,8 do
                                for p = 1,j-1 do
                                    if k - x == y - p then
                                        bishop[k][p] = nil
                                    end
                                end
                            end

                        end
                    end
                end
            end
        end
        for i = 1,8 do
            for j = 1,8 do
                if (string.match(FENarr[i][j], "[k]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[K]") and FEN[2] == "w") then
                    if bishop[i][j] ~= nil and i + y == j + x then
                        if i < x then
                            for k = 1,8 do
                                for p = j+1,y do
                                    if k + y == p + x then
                                        checking[k][p] = "x"
                                    end
                                end
                            end
                        else
                            for k = 1,8 do
                                for p = y,j-1 do
                                    if k + y == p + x then
                                        checking[k][p] = "x"
                                    end
                                end
                            end
                        end
                    elseif bishop[i][j] ~= nil and i - x == y - j then
                        if i < x then
                            for k = 1,8 do
                                for p = y,j-1 do
                                    if k - x == y - p then
                                        checking[k][p] = "x"
                                    end
                                end
                            end
                        else
                            for k = 1,8 do
                                for p = j+1,y do
                                    if k - x == y - p then
                                        checking[k][p] = "x"
                                    end
                                end
                            end
                        end
                        attackers = attackers + 1
                    end
                end
            end
        end
        bishop[x][y] = nil
        return bishop
    end

    -- moves for king
    local function king(x,y)
        local king = empty_array()
        for i = x-1,x+1 do
            for j = y-1,y+1 do
                if i <= 8 and i >= 1 and j <= 8 and j >= 1 then
                    king[i][j] = "x"
                    if (string.match(FENarr[i][j], "[r,n,b,q,p]") and FENarr[x][y] == "k") or (string.match(FENarr[i][j], "[R,N,B,Q,P]") and FENarr[x][y] == "K") then
                        king[i][j] = nil
                        attacked[i][j] = "x"
                    end
                end
            end
        end
        king[x][y] = nil
        return king
    end

    -- generate knight moves
    local function knight(x,y)

        local knight = empty_array()

        local m = {}
        m[x+2] = {}
        m[x-2] = {}

        for i = x-1,x+1,2 do
            m[i] = {}
            for j = y-1,y+1,2 do
                local n = nil
                if j <= 8 and j >= 1 then
                    if i == x + 1 and i < 8 then
                        table.insert(m[i+1], j)
                    end
                    if i == x - 1 and i > 1 then
                        table.insert(m[i-1], j)
                    end
                end
                if i <= 8 and i >= 1 then
                    if j == y + 1 and j < 8 then
                        table.insert(m[i], j+1)
                    end
                    if j == y - 1 and j > 1 then
                        table.insert(m[i], j-1)
                    end
                end
            end
        end

        for k,v in pairs(m) do
            for i = 1,#v do
                knight[k][v[i]] = "x"

                if (string.match(FENarr[k][v[i]], "[r,n,b,q,p]") and FENarr[x][y] == "n") or (string.match(FENarr[k][v[i]], "[R,N,B,Q,P]") and FENarr[x][y] == "N") then
                    knight[k][v[i]] = nil
                    attacked[k][v[i]] = "x"
                end

                if (string.match(FENarr[k][v[i]], "[K]") and FENarr[x][y] == "n") or (string.match(FENarr[k][v[i]], "[k]") and FENarr[x][y] == "N") then
                    checking[x][y] = "x"
                    attackers = attackers + 1
                end
            end
        end
        return knight
    end

    local function pawn(x, y, attack)
        local pawn = empty_array()
        if FEN[2] == "w" then
            n = 1
        else
            n = -1
        end
        if attack then
            pawn[x+n][y-1] = "x"
            pawn[x+n][y+1] = "x"
        else
            if x - n ~= nil then
                pawn[x-n][y] = "x"
                if (x == 2 and FEN[2] == "b") or (x == 7 and FEN[2] == "w") then
                    pawn[x-2*n][y] = "x"
                end
            end
        end
        return pawn
    end

    local function queen(x,y)

        local r = rook(x,y)
        local b = bishop(x,y)

        --local r = empty_array()
        --b = empty_array()

        local queen = empty_array()
        for i = 1,8 do
            for j = 1,8 do
                if r[i][j] ~= nil or b[i][j] ~= nil then
                    queen[i][j] = "x"
                    --checking[i][j] = "x"
                    if (string.match(FENarr[i][j], "[r,n,b,q,p,k]") and FENarr[x][y] == "q") or (string.match(FENarr[i][j], "[R,N,B,Q,P,K]") and FENarr[x][y] == "Q") then
                        --queen[i][j] = nil
                        --attacked[i][j] = "x"
                    end
                end
            end
            --io.write('\n')
        end
        return queen
    end

    local function update_attacked(t)
        for x = 1,8 do
            for y = 1,8 do
                if t[x][y] ~= nil or attacked[x][y] ~= nil then
                    attacked[x][y] = "x"
                end
            end
        end
    end

    -- generate attacked squares
    for i = 1,8 do
        for j = 1,8 do
            if (string.match(FENarr[i][j], "[R]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[r]") and FEN[2] == "w") then
                update_attacked(rook(i,j))
            elseif (string.match(FENarr[i][j], "[B]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[b]") and FEN[2] == "w") then
                update_attacked(bishop(i,j))
            elseif (string.match(FENarr[i][j], "[Q]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[q]") and FEN[2] == "w") then
                update_attacked(queen(i,j))
            elseif (string.match(FENarr[i][j], "[N]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[n]") and FEN[2] == "w") then
                update_attacked(knight(i,j))
            elseif (string.match(FENarr[i][j], "[K]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[k]") and FEN[2] == "w") then
                update_attacked(king(i,j))
            elseif (string.match(FENarr[i][j], "[P]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[p]") and FEN[2] == "w") then
                update_attacked(pawn(i,j, true))
            end
        end
    end

    for i = 1,8 do
        for j = 1,8 do
            --print(attacked[i][j])
            if checking[i][j] ~= nil then
                io.write("x ")
            elseif attacked[i][j] ~= nil then
                io.write("* ")
            else
                io.write(". ")
            end
        end
        io.write('\n')
    end
    io.write("================\n")

    -- Generate valid moves
    local uci = {}
    local move = ""

    check = false
    kingi = nil
    kingj = nil

    local function move_to_uci(x,y)
        move = move:sub(1, 2) .. string.char(96+y) .. move:sub(4)
        move = move:sub(1, 3) .. 9-x .. move:sub(5)
        table.insert(uci, move)
    end

    local function gen_moves(t)
        for x = 1,8 do
            for y = 1,8 do
                if check then
                    if attackers < 2 then
                        if t[x][y] ~= nil and checking[x][y] ~= nil then
                            move_to_uci(x,y)
                        end
                    end
                else
                    if t[x][y] ~= nil then
                        move_to_uci(x,y)
                    end
                end
            end
        end
    end

    local function king_moves(t)
        for x = 1,8 do
            for y = 1,8 do
                if t[x][y] ~= nil and attacked[x][y] == nil then
                    print(x,y)
                    move_to_uci(x,y)
                end
            end
        end
    end

    for i = 1,8 do
        for j = 1,8 do
            if (string.match(FENarr[i][j], "[k]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[K]") and FEN[2] == "w") then
                if attacked[i][j] ~= nil then
                    check = true
                end
            end
        end
    end

    for i = 1,8 do
        for j = 1,8 do
            io.write(FENarr[i][j], " ")
        end
        io.write('\n')
    end
    print("================")

    for i = 1,8 do
        for j = 1,8 do
            move = move:sub(1, 0) .. string.char(96+j) .. move:sub(2)
            move = move:sub(1, 1) .. 9-i .. move:sub(3)
            if (string.match(FENarr[i][j], "[k]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[K]") and FEN[2] == "w") then
                king_moves(king(i,j))
            elseif (string.match(FENarr[i][j], "[r]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[R]") and FEN[2] == "w") then
                gen_moves(rook(i,j))
            elseif (string.match(FENarr[i][j], "[n]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[N]") and FEN[2] == "w") then
                gen_moves(knight(i,j))
            elseif (string.match(FENarr[i][j], "[b]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[B]") and FEN[2] == "w") then
                gen_moves(bishop(i,j))
            elseif (string.match(FENarr[i][j], "[p]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[P]") and FEN[2] == "w") then
                gen_moves(pawn(i,j))
            elseif (string.match(FENarr[i][j], "[q]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[Q]") and FEN[2] == "w") then
                gen_moves(queen(i,j))
            end
            --print(FENarr[i][j], #uci)
        end
    end

    for i = 1,8 do
        for j = 1,8 do
            --print(attacked[i][j])
            if checking[i][j] ~= nil then
                io.write("x ")
            elseif attacked[i][j] ~= nil then
                io.write("* ")
            else
                io.write(". ")
            end
        end
        io.write('\n')
    end
    io.write("================\n")
    if check then
        --uci = {}
        --move = move:sub(1, 0) .. string.char(96+kingj) .. move:sub(2)
        --move = move:sub(1, 1) .. 9-kingi .. move:sub(3)
        --king_moves(king(kingi,kingj))
        --print(string.char(96+kingj), 9-kingi)
    end

    print(#uci)
    for i = 1,#uci do
        print(uci[i])
    end

    -- return all valid moves and their popularity in a table
    return moves
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
