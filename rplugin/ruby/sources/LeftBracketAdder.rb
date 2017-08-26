require_relative "CurrentLine.rb"
require_relative "BracketAdder.rb"

class Point

    attr_accessor :x,:y

    def initialize(*args)
        @x,@y=args
    end
end

class LeftBracketAdder

  def initialize(buffer, line_number, caret)
    complete = CompleteLine.new
    @buffer = buffer
    @lines, modified_begin_x, modified_end_x, modified_begin_y = complete.get_complete_line(buffer, line_number, caret)
    @caret_location = Point.new(caret, line_number - modified_begin_y)

    @modified_begin_location = Point.new(modified_begin_x, modified_begin_y)
    @modified_end_location = Point.new(modified_end_x, modified_begin_y + @lines.count - 1)
  end

  # debug only
  def buffer()
    return @buffer
  end

  def get_inserted_line()

    # add_missing_bracket only works on single line
    line = @lines.join("\n")
    adder = BracketAdder.new

    # don't include the last line (current editing line)
    # caret location in last line
    # "\n" in each line before the last line
    prev_length = @caret_location.y == 0 ? 0 : @lines[0..(@caret_location.y-1)].map { |str| str.length }.reduce(0,:+)
    caret_in_single_line = prev_length + @caret_location.x + @caret_location.y

    # make sure the cursor stays in the line (including the boundary)
    # otherwise BracketAdder will crash
    caret_in_single_line = [caret_in_single_line, line.length].min

    return adder.add_missing_bracket(line, caret_in_single_line)
  end

  # modified the existing buffer
  # returns the new caret position (after it inserts "]")
  def apply_inserted_line()
    inserted_lines = self.get_inserted_line

    # return original caret
    return @caret_location.x unless inserted_lines

    modified_lines = inserted_lines.split("\n")

    if @modified_begin_location.x > 0
      first_line = @buffer[@modified_begin_location.y]
      modified_lines[0] =  first_line[0..@modified_begin_location.x - 1] + modified_lines[0]
    end

    # find and remove $0 (the caret after insertion)
    current_line = modified_lines[@caret_location.y]

    match = current_line.match(/\$0/)

    return @caret_location.x unless match # something is wrong

    index = match.begin(0)

    if index > 0
      modified_lines[@caret_location.y] = current_line[0..index-1] + current_line[index+2..-1]
    else
      modified_lines[@caret_location.y] = current_line[2..-1]
    end

    # the lines after @caret will not be modified
    for i in (0..@caret_location.y) 
      if modified_lines[i] != @lines[i]
        @buffer[i + @modified_begin_location.y] = modified_lines[i]
      end
    end

    return index
  end
end

if __FILE__ == $PROGRAM_NAME

  # nvim buffer is 1-index
  #buffer = [0, "aa bb;"]
  #caret = 5
  #insert = LeftBracketAdder.new(buffer, buffer.length - 1, caret)
  #puts insert.apply_inserted_line()
  #puts insert.buffer

  #buffer = [0, "b ", "a ; ", "{aa ;}bb", "cc dd;"]
  #caret = 5
  #insert = LeftBracketAdder.new(buffer, buffer.length - 1, caret)
  #puts insert.get_inserted_line()

  #buffer = [0, "[a b]", ""]
  #caret = 0
  #insert = LeftBracketAdder.new(buffer, buffer.length - 1, caret)
  #puts insert.apply_inserted_line()
  #puts insert.buffer

  #buffer = [0, "; a b"]
  #caret = 5
  #insert = LeftBracketAdder.new(buffer, buffer.length - 1, caret)
  #puts insert.apply_inserted_line()
  #puts insert.buffer

  # SETUP: start nvim in another terminal by "NVIM_LISTEN_ADDRESS=/tmp/nvim.sock nvim"
  # then run this script to test
 
  require "neovim"
  client = Neovim.attach_unix("/tmp/nvim.sock")

  buffer = client.get_current_buf
  caret = client.get_current_line
  window = client.get_current_win
  y, x = window.cursor
  line_num = buffer.line_number
  puts "cursor", [y, x]
  puts "totoal line",line_num
  insert = LeftBracketAdder.new(buffer, line_num, x)
  puts buffer.lines
  new_x = insert.apply_inserted_line()
  window.cursor = [y, new_x]
  puts insert.buffer[0]

end
