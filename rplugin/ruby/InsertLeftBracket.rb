require_relative "sources/LeftBracketAdder.rb"

Neovim.plugin do |plug|

  plug.command(:InsertLeftBracket, :nargs => 0, :sync => true) do |client|
    buffer = client.get_current_buf
    caret = client.get_current_line
    window = client.get_current_win
    y, x = window.cursor
    line_num = buffer.line_number
    insert = LeftBracketAdder.new(buffer, line_num, x)
    new_x = insert.apply_inserted_line()
    window.cursor = [y, new_x]
  end

  plug.autocmd(:BufEnter, :pattern => "*.m") do |nvim|
    nvim.command("inoremap ] <C-O>:InsertLeftBracket<CR>")
  end
end
