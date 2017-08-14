#require "neovim"
#client = Neovim.attach_unix("/tmp/nvim.sock")
    #buffer = client.get_current_buf

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
    end_x_position = caret_placement
    partial_line = ""
    (1..current_line_number).reverse_each { |i|
      line = buffer[i]
      line_length = line.length
      line.reverse.each_char.with_index { |val, ind|
        ind = line_length - 1 - ind
        if i == current_line_number and ind >= caret_placement
          # search ';' before the cursor position
          next
        end
        if state == :INITIAL_STATE
          if val == ';'
            # we find the complete line
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
        end_x_position = ind
      } # end each line character

      if state == :END_STATE
        if partial_line.length > 0
          lines.insert(0, partial_line)
        end
        break
      else
        end_x_position = 0
        lines.insert(0, line)
      end
    } # end current_line_number

    return [lines, end_x_position]
  end # end get_complete_line

end # end CompleteLine

if __FILE__ == $PROGRAM_NAME
  complete = CompleteLine.new

  # nvim buffer is 1-index
  buffer = [0, "aa bb"]
  line_number = 1
  res = complete.get_complete_line(buffer, line_number, 4)
  raise String(res) unless res == [["aa bb"], 0]

  # caret is located before the last ;
  buffer = [0, "aa ;bb", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["bb", "cc dd;"], 4]

  buffer = [0, "aa;", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["cc dd;"], 0]

  # caret is located at the last ;
  buffer = [0, "aa ;bb", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 6)
  raise String(res) unless res == [[], 6]

  buffer = [0, "{aa ;}bb", "cc dd;"]
  line_number = 2
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["{aa ;}bb", "cc dd;"], 0]

  buffer = [0, "b ", "a;", "{aa ;}bb", "cc dd;"]
  line_number = 4
  res = complete.get_complete_line(buffer, line_number, 5)
  raise String(res) unless res == [["{aa ;}bb", "cc dd;"], 0]
end
