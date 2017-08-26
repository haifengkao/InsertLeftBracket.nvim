
class CompleteLine

  # buffer a neovim buffer object
  # current_line_number  the current line number (1-index)
  def get_complete_line(buffer, current_line_number, caret_placement)
    if !buffer
      return
    end

    state = :INITIAL_STATE
    right_curly_bracket_num = 0
    
    lines = []
    start_x_position = caret_placement
    partial_line = ""

    current_line_length = 0

    # find the beginning x position of complete line 
    (1..current_line_number).reverse_each { |i|
      line = buffer[i]
      line_length = line.length
      if i == current_line_number
        current_line_length = line_length
      end
      line.reverse.each_char.with_index { |val, ind|
        ind = line_length - 1 - ind
        if i == current_line_number and ind >= caret_placement
          # search ';' before the cursor position
          next
        end
        if state == :INITIAL_STATE
          if val == ';' or val == '{'
            # we find the complete line after ';' or inside {}
            state = :END_STATE 
            partial_line = line[ind+1..-1]
            break
          elsif val == '}'
            # inside a block
            state = :GET_RIGHT_CURLY_BRACKET
            right_curly_bracket_num = right_curly_bracket_num + 1
          end
        elsif state == :GET_RIGHT_CURLY_BRACKET
          if val == '{'
            right_curly_bracket_num = right_curly_bracket_num - 1
            if right_curly_bracket_num <= 0
              right_curly_bracket_num = 0
              # leaving the block
              state = :INITIAL_STATE
            end
          end
        end
        start_x_position = ind
      } # end each line character

      if state == :END_STATE
        # should always put something in lines (event an empty string)
        # otherwise, ] cnnot be inserted
        if lines.count == 0 or partial_line.length > 0
          lines.insert(0, partial_line)
        end
        break
      else
        start_x_position = 0
        lines.insert(0, line)
      end
    } # end current_line_number

    state = :INITIAL_STATE
    partial_line = ""
    left_curly_bracket_num = 0
    end_x_position = current_line_length # it's possible that the current line is the last line

    # find the beginning y position of complete line
    begin_y_position = current_line_number - lines.length + 1
    
    # find the ending x position of complete line
    number_of_lines = buffer.count
    (current_line_number+1..number_of_lines-1).each { |i|
      line = buffer[i]
      line_length = line.length
      line.each_char.with_index { |val, ind|
        if state == :INITIAL_STATE
          if val == ';' or val == '}'
            # we find the complete line after ';' or inside {}
            state = :END_STATE 
            partial_line = line[0..ind]
            break
          elsif val == '{'
            # inside a block
            state = :GET_LEFT_CURLY_BRACKET
            left_curly_bracket_num = left_curly_bracket_num + 1
          end
        elsif state == :GET_LEFT_CURLY_BRACKET
          if val == '}'
            left_curly_bracket_num = left_curly_bracket_num - 1
            if left_curly_bracket_num <= 0
              left_curly_bracket_num = 0
              # leaving the block
              state = :INITIAL_STATE
            end
          end
        end
        end_x_position = ind
      } # end each line character

      if state == :END_STATE
        if partial_line.length > 0
          lines.push(partial_line)
        end
        break
      else
        end_x_position = 0
        lines.push(line)
      end
    } # end current_line_number

    return [lines, start_x_position, end_x_position, begin_y_position]
  end # end get_complete_line

end # end CompleteLine

if __FILE__ == $PROGRAM_NAME
  complete = CompleteLine.new

  # nvim buffer is 1-index
  buffer = [0, "aa bb"]
  line_number = 1
  res = complete.get_complete_line(buffer, line_number, 4)
  raise String(res) unless res == [["aa bb"], 0, 5, 1]

  # caret is located before the last ;
  buffer = [0, "aa ;bb", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["bb", "cc dd;"], 4, 6, 1]

  buffer = [0, "aa;", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["cc dd;"], 0, 6, 2]

  # caret is located at the last ;
  buffer = [0, "aa ;bb", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 6)
  raise String(res) unless res == [[""], 6, 6, 2]

  buffer = [0, "{aa ;}bb", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["{aa ;}bb", "cc dd;"], 0, 6, 1]

  buffer = [0, "b ", "a;", "{aa ;}bb", "cc dd;"]
  line_number = 4
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["{aa ;}bb", "cc dd;"], 0, 6, 3]

  buffer = [0, "; a b "]
  line_number = 1
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [[" a b "], 1, 6, 1]

  buffer = [0, "[a b:^(){ return c d "]
  line_number = 1
  res = complete.get_complete_line(buffer, line_number, 21)
  raise String(res) unless res == [[" return c d "], 9, 21, 1]

end
