#require "neovim"
#client = Neovim.attach_unix("/tmp/nvim.sock")
    #buffer = client.get_current_buf
require "./CurrentLine.rb"
require "./BracketAdder.rb"

class Point

    attr_accessor :x,:y

    def initialize(*args)
        @x,@y=args
    end
end

class InsertLeftBracket

  def initialize(buffer, line_number, caret)
    complete = CompleteLine.new
    @caret = caret
    @lines, modified_begin_x = complete.get_complete_line(buffer, line_number, caret)
    modified_begin_y = line_number - @lines.length + 1

    @modified_begin_location = Point.new(modified_begin_x, modified_begin_y)
  end

  def get_inserted_line()

    # add_missing_bracket only works on single line
    line = @lines.join("\n")
    adder = BracketAdder.new

    # don't include the last line (current editing line)
    # caret location in last line
    # "\n" in each line before the last line
    caret_in_single_line = @lines[0..-2].map { |str| str.length }.reduce(0,:+) + @caret +  @lines.length - 1 
    return adder.add_missing_bracket(line, caret_in_single_line)
  end
end


if __FILE__ == $PROGRAM_NAME

  # nvim buffer is 1-index
  buffer = [0, "aa bb;"]
  caret = 4
  insert = InsertLeftBracket.new(buffer, buffer.length - 1, caret)
  puts insert.get_inserted_line()

  buffer = [0, "b ", "a ; ", "{aa ;}bb", "cc dd;"]
  caret = 4
  insert = InsertLeftBracket.new(buffer, buffer.length - 1, caret)
  puts insert.get_inserted_line()
end
