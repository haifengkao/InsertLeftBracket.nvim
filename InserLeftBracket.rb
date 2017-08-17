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
    @buffer = buffer
    @caret = caret
    @lines, modified_begin_x = complete.get_complete_line(buffer, line_number, caret)

    modified_begin_y = line_number - @lines.length + 1

    @modified_begin_location = Point.new(modified_begin_x, modified_begin_y)
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
    caret_in_single_line = @lines[0..-2].map { |str| str.length }.reduce(0,:+) + @caret +  @lines.length - 1 

    # make sure the cursor stays in the line
    # otherwise BracketAdder will crash
    caret_in_single_line = [caret_in_single_line, line.length - 1].min

    return adder.add_missing_bracket(line, caret_in_single_line)
  end

  # modified the existing buffer
  # returns the new caret position (after it inserts "]")
  def apply_inserted_line()
    inserted_lines = self.get_inserted_line

    return unless inserted_lines

    modified_lines = inserted_lines.split("\n")

    # find and remove $0 (the caret after insertion)
    last_line = modified_lines[-1]

    match = last_line.match(/\$0/)

    return unless match # something is wrong

    index = match.begin(0)

    if index > 0
      modified_lines[-1] = last_line[0..index-1] + last_line[index+2..-1]
    else
      modified_lines[-1] = last_line[2..-1]
    end

    for i in (0..@lines.length) 
      if modified_lines[i] != @lines[i]
        @buffer[i + @modified_begin_location.y] = modified_lines[i]
      end
    end

    return index
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

  buffer = [0, "[a b]", ""]
  caret = 0
  insert = InsertLeftBracket.new(buffer, buffer.length - 1, caret)
  puts insert.apply_inserted_line()
  puts insert.buffer

end
