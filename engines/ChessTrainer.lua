
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
require("FEN")
local http = require("socket.http")
local lunajson = require("lunajson")

file = io.open("output.txt", "w+")

local moves = {}

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
                board.startpos = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
                board.fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
                --print("info string ", cmd[4], cmd[5], cmd[6])
                --print("info string ", FEN.fenstr_move(board.fen, cmd[4]))
            end
            if cmd[2] == "fen" then
                board.fen = ""
                board.startpos = ""
                for i = 3,#cmd do
                    board.startpos = board.startpos..cmd[i].." "
                    board.fen = board.fen..cmd[i].." "
                end
            end
            for n = 1,#cmd do
                if cmd[n] == "moves" then
                    board.moves = ""
                    for i = n+1,#cmd do
                        board.moves = board.moves..cmd[i]..","
                        fen(cmd[i])
                    end
                    file:write(board.fen, "\n")
                    print("info string ", board.fen)
                end
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

