
require("math")
require "fun" ()
local http = require("socket.http")
local lunajson = require("lunajson")

board = {}
board.startpos = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
board.fen = board.startpos
board.moves = ""

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

local function FENtoarr()
    -- put FEN into modifiable array
    -- split board.fen by spaces
    FEN = {}
    for str in string.gmatch(board.fen, "([^".."%s".."]+)") do
        table.insert(FEN, str)
    end
    -- split FEN[1] by "/"
    local newboard = {}
    for str in string.gmatch(FEN[1], "([^".."/".."]+)") do
        table.insert(newboard, str)
    end
    -- put result into array
    local FENarr = empty_array()
    for i = 1,8 do
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
    return FENarr
end

local function valid_moves()

    local FENarr = FENtoarr()
    local attackers = 0

    -- initialise attacked and checking squares array
    local attacked = empty_array()
    local checking = empty_array()

    -- moves for rook
    local function rook(x,y)
        local rook = empty_array()
        local local_attacked = empty_array()

        local t = {}
        t[x] = {}
        for _it, i in range(8) do
            table.insert(t[x], i)
            if i ~= x then
                t[i] = {}
                table.insert(t[i], y)
            end
        end

        local function moves()
            for k,v in pairs(t) do
                for i = 1,#v do
                    rook[k][v[i]] = true
                    -- if there is a piece blocking
                    if (string.match(FENarr[k][v[i]], "[r,n,b,q,p,k,R,N,B,Q,P]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[k][v[i]], "[r,n,b,q,p,R,N,B,Q,P,K]") and string.match(FENarr[x][y], "[R,Q]")) then
                        -- if the piece is of the same colour
                        if ((string.match(FENarr[k][v[i]], "[r,n,b,q,p,k]") and string.match(FENarr[x][y], "[r,q]")) or (string.match(FENarr[k][v[i]], "[R,N,B,Q,P,K]") and string.match(FENarr[x][y], "[R,Q]"))) and rook[k][v[i]] ~= nil and not (k == x and v[i] == y) then
                            rook[k][v[i]] = nil
                            if attacked[k][v[i]] == nil and i < y then
                                for j = 1,i-1 do
                                    local_attacked[x][j] = nil
                                end

                            end
                            local_attacked[k][v[i]] = true
                        end

                        if v[i] < y then
                            -- left side of rook
                            for _it,v in range(0,i-1) do
                                rook[x][v] = nil
                            end
                            for _it,v in range(0,y) do
                                checking[x][v] = nil
                            end
                        elseif v[i] > y then
                            -- right
                            break
                        end

                        if k < x then
                            -- top side of rook
                            for _it,j in range(0,k-1) do
                                if j ~= 0 then
                                    local_attacked[j][y] = nil
                                    rook[j][y] = nil

                                end
                            end
                            for _it,v in range(1,x) do
                                --checking[v][y] = nil
                            end
                        elseif k > x then
                            -- bottom
                            return
                        end
                    end
                end
            end
        end
        moves()
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
        -- do not go any further
        local bishop = empty_array()
        bishop [x] = {}
        for i = 1,8 do
            for j = 1,8 do
                if i + y == j + x or i == -j + x + y then
                    bishop[i][j] = true
                end
            end
        end
        for i = 1,8 do
            for j = 1,8 do
                if string.match(FENarr[i][j], "[r,n,b,q,p,R,N,B,Q,P]") or (string.match(FENarr[i][j], "[k]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[K]") and FEN[2] == "w") then
                    if i + y == j + x then
                        if (string.match(FENarr[x][i], "[r,n,b,q,p]") and string.match(FENarr[x][y], "[b,q]")) or (string.match(FENarr[x][i], "[R,N,B,Q,P]") and string.match(FENarr[x][y], "[B,Q]")) then

                            bishop[i][j] = nil
                            attacked[i][j] = true
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
                            attacked[i][j] = true
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
                                        checking[k][p] = true
                                    end
                                end
                            end
                        else
                            for k = 1,8 do
                                for p = y,j-1 do
                                    if k + y == p + x then
                                        checking[k][p] = true
                                    end
                                end
                            end
                        end
                    elseif bishop[i][j] ~= nil and i - x == y - j then
                        if i < x then
                            for k = 1,8 do
                                for p = y,j-1 do
                                    if k - x == y - p then
                                        checking[k][p] = true
                                    end
                                end
                            end
                        else
                            for k = 1,8 do
                                for p = j+1,y do
                                    if k - x == y - p then
                                        checking[k][p] = true
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
                    king[i][j] = true
                    if (string.match(FENarr[i][j], "[r,n,b,q,p]") and FENarr[x][y] == "k") or (string.match(FENarr[i][j], "[R,N,B,Q,P]") and FENarr[x][y] == "K") then
                        king[i][j] = nil
                        attacked[i][j] = true
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

        -- make table of squares to move to
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

        -- fill those squares
        for k,v in pairs(m) do
            for i = 1,#v do
                knight[k][v[i]] = true
                -- if piece is same colour
                if (string.match(FENarr[k][v[i]], "[r,n,b,q,p]") and FENarr[x][y] == "n") or (string.match(FENarr[k][v[i]], "[R,N,B,Q,P]") and FENarr[x][y] == "N") then
                    knight[k][v[i]] = nil
                    attacked[k][v[i]] = true
                end
                -- if piece is enemy king
                if (string.match(FENarr[k][v[i]], "[K]") and FENarr[x][y] == "n") or (string.match(FENarr[k][v[i]], "[k]") and FENarr[x][y] == "N") then
                    checking[x][y] = true
                    attackers = attackers + 1
                end
            end
        end
        return knight
    end

    -- moves for pawn
    local function pawn(x, y, attack)
        --checking = empty_array()
        local pawn = empty_array()
        -- many conditions
        if FENarr[x][y] == "p" then
            n = 1
        else
            n = -1
        end

        if x + n > 0 and x + n < 9 then
            if FENarr[x+n][y] == nil then
            pawn[x+n][y] = true
                if (x == 2 and FEN[2] == "b") or (x == 7 and FEN[2] == "w") and FENarr[x+2*n][y] == nil then
                    pawn[x+2*n][y] = true
                end
            end

            if x ~= 8 and y > 1 and (attack or (string.match(FENarr[x+n][y-1], "[r,n,b,q,k]") and FENarr[x][y] == "P") or (string.match(FENarr[x+n][y-1], "[R,N,B,Q,K]") and FENarr[x][y] == "p")) then
                pawn[x+n][y-1] = true
                print(x, y)
                print(x+n, y-1)
            end
            if x ~= 8 and y < 8 and (attack or (string.match(FENarr[x+n][y+1], "[r,n,b,q,k]") and FENarr[x][y] == "P") or (string.match(FENarr[x+n][y+1], "[R,N,B,Q,K]") and FENarr[x][y] == "p")) then
                pawn[x+n][y+1] = true
            end
        end

        return pawn
    end

    -- moves for queen
    local function queen(x,y)
        local queen = empty_array()

        -- the queen moves like a rook and a bishop
        local r = rook(x,y)
        local b = bishop(x,y)

        --combine rook and bishop moves
        for i = 1,8 do
            for j = 1,8 do
                if r[i][j] ~= nil or b[i][j] ~= nil then
                    queen[i][j] = true
                end
            end
        end
        return queen
    end

    -- update the attacked array with any 8x8 table
    local function update_attacked(t)
        for x = 1,8 do
            for y = 1,8 do
                if t[x][y] ~= nil or attacked[x][y] ~= nil then
                    attacked[x][y] = true
                end
            end
        end
    end

    -- generate attacked squares for each piece
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

    -- decide if the king is in check
    check = false
    for i = 1,8 do
        for j = 1,8 do
            if (string.match(FENarr[i][j], "[k]") and FEN[2] == "b") or (string.match(FENarr[i][j], "[K]") and FEN[2] == "w") then
                if attacked[i][j] ~= nil then
                    check = true
                end
            end
        end
    end

    -- put the move into uci format
    local function move_to_uci(x,y)
        move = move:sub(1, 2) .. string.char(96+y) .. move:sub(4)
        move = move:sub(1, 3) .. 9-x .. move:sub(5)
        table.insert(uci, move)
    end

    -- generate moves from a table of valid moves to put into uci
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

    -- special function for a special king
    local function king_moves(t)
        for x = 1,8 do
            for y = 1,8 do
                if t[x][y] ~= nil and attacked[x][y] == nil then
                    move_to_uci(x,y)
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

    -- get valid moves for each piece in each position in FENarr
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

    local moves = {}
    for i = 1,#uci do
        print(uci[i])
        local t = {}
        t["white"] = 0
        t["averageRating"] = 0
        t["draws"] = 0
        t["uci"] = uci[i]
        t["black"] = 0
        t["san"] = nil
        table.insert(moves, t)
    end

    -- return all valid moves
    return moves
end


local function database()
    --print(board.fen)
    --[[ Function to return values from json body ]]--
    --[[ turn board.fen into http valid link ]]--
    rep = "https://explorer.lichess.ovh/lichess?variant=standard&speeds[]=bullet&speeds[]=blitz&speeds[]=rapid&speeds[]=classical&ratings[]=1600&ratings[]=1800&ratings[]=2000&ratings[]=2200&ratings[]=2500&moves=50&play="..board.moves.."&fen="..string.gsub(board.startpos, "%s+", "%%20")
    --print(rep)
    res = http.request(rep)
    res_parsed = lunajson.decode(res)
    local moves = res_parsed["moves"]

    if #moves == 0 or moves[1]["white"] + moves[1]["draws"] + moves[1]["black"] < 2 then
        moves = valid_moves()
    end

    -- return valid moves and their popularity in a table
    return moves
end

function move()
    moves = database()
    print(#moves)
    --print(board.moves)
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
    for i = 1,#moves do
        --print(moves[i]["san"], moves[i]["total"])
        if moves[i]["total"] > r then
            --print("info string", sum)
            return "bestmove "..moves[i]["uci"]
        else
            r = r - moves[i]["total"]
        end
    end
    r = math.random(#moves)
    return "bestmove "..moves[r]["uci"]
end

function fen(move)

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
    --print(board.fen)
end

str = "e2e4 e7e6 d2d4 d7d5 b1c3 f8b4 a2a3 b4c3 b2c3 g8f6 e4d5 d8d5 c1g5 b8d7 d1f3 a8b8 f3d5 f6g8 d5d7 e8f8 d7e7 g8e7 g5e7 f8e7 e1c1 b8a8 g1f3 h8g8 f3e5 g8f8 e5g6 h7g6 f1a6 f8h8 a6b7 a8b8 b7c8 b8a8 c8e6 h8h7 e6f7 a8e8 f7g6 e8a8 g6h7 e7e8 d1e1 e8f8 e1e4 a8b8 h1e1 b8d8 h7g6 d8a8 e4e8"
for s in string.gmatch(str, "([^".."%s".."]+)") do
    board.moves = board.moves..s..","
    fen(s)
end


--fen("e2e4")
--fen("c7c5")
--fen("b1c3")
--fen("d7d6")
print(move())
