require "curses"

class Spreadshit
  class Window
    class Address < Struct.new(:col, :row)
      def to_s
        [col, row].join
      end

      def to_sym
        to_s.to_sym
      end
    end

    class SpreadsheetDelegate
      [:cell_updated, :cell_value, :cell_content, :cell_dependents, :cell_dependencies].each do |delegate|
        define_method delegate do |&block|
          block ?
            instance_variable_set("@#{delegate}", block) :
            instance_variable_get("@#{delegate}")
        end
      end

      def initialize
        @cell_updated = @cell_value = @cell_value = @cell_dependents = @cell_dependencies = Proc.new {}
      end
    end

    class Error < Struct.new(:message)
      def to_s
        message
      end
    end

    class ReferenceError < Error; end
    class NameError < Error; end
    class ValueError < Error; end

    include Curses

    def initialize
      @mode = :navigation
      @x, @y = 0, 0
      @sx, @sy = 0, 0
      @col_width = 13
      @letters = ("A".."ZZZ").to_a

      @show_dependencies = false

      @spreadsheet_delegate = SpreadsheetDelegate.new
      yield @spreadsheet_delegate
    end

    def start
      init_screen
      start_color
      init_pair(COLOR_WHITE, COLOR_BLACK, COLOR_WHITE)
      init_pair(COLOR_BLUE, COLOR_BLACK, COLOR_BLUE)
      init_pair(COLOR_GREEN, COLOR_BLACK, COLOR_GREEN)
      init_pair(COLOR_RED, COLOR_BLACK, COLOR_MAGENTA)
      init_pair(COLOR_YELLOW, COLOR_BLACK, COLOR_YELLOW)
      init_pair(COLOR_CYAN, COLOR_BLACK, COLOR_CYAN)
      use_default_colors
      redraw

      loop { capture_input }
    end

    private

    def max_cols
      cols / @col_width
    end

    def max_rows
      lines - 3
    end

    def address
      Address.new(@letters[@x], @y + 1)
    end

    def current_cell_value
      cell_value_at(address)
    end

    def cell_value_at(address)
      @spreadsheet_delegate.cell_value.call(address)
    end

    def current_cell_content
      @spreadsheet_delegate.cell_content.call(address)
    end

    def current_cell_content=(value)
      @spreadsheet_delegate.cell_updated.call(address, value)
    end

    def current_cell_dependencies
      @spreadsheet_delegate.cell_dependencies.call(address) || []
    end

    def current_cell_dependents
      @spreadsheet_delegate.cell_dependents.call(address) || []
    end

    def capture_input
      case @mode
      when :navigation
        curs_set(0)
        navigate
      when :edit
        redraw
        curs_set(2)
        read_cell_definition
      end
    end

    def navigate
      cbreak
      noecho
      stdscr.keypad = true
      case getch
      when KEY_UP
        @y -= 1
        @y = 0 if @y < 0
        @sy -= 1 if @y < @sy
        @sy = 0 if @sy < 0
      when KEY_DOWN
        @y += 1
        @sy += 1 if @y >= max_rows
      when KEY_LEFT
        @x -= 1
        @x = 0 if @x < 0
        @sx -= 1 if @x < @sx
        @sx = 0 if @sx < 0
      when KEY_RIGHT
        @x += 1
        @sx += 1 if @x >= max_cols
      when 10
        @mode = :edit
      when "d", "D"
        @show_dependencies = !@show_dependencies
      when 27
        exit 0
      else
        return
      end

      redraw
    end

    def read_cell_definition
      echo
      self.current_cell_content = getstr
      @mode = :navigation
      redraw
    end

    def redraw
      draw_cells
      draw_letters_header
      draw_numbers_header
      draw_text_field
      cursor_to_input_line
      refresh
    end

    def draw_text_field
      setpos(divider_line, 0)

      case @mode
      when :navigation
        dependencies_text = if @show_dependencies
          " and D to hide dependencies"
        else
          " and D to show dependencies"
        end

        draw_divider(
          color: color_pair(COLOR_RED) | A_NORMAL,
          left_text: current_cell_value.to_s,
          center_text: "Press ENTER to edit #{address}" + dependencies_text
        )
        cursor_to_input_line
        addstr(current_cell_content.to_s)
        clrtoeol
      when :edit
        draw_divider(
          color: color_pair(COLOR_GREEN) | A_NORMAL,
          left_text: current_cell_content.to_s,
          center_text: "Editing #{address}"
        )
        cursor_to_input_line
        clrtoeol
      end
    end

    def draw_divider(color: color_pair(COLOR_GREEN) | A_NORMAL, left_text: "", right_text: "", center_text: "")
      attron color do
        setpos(divider_line, 0)
        addstr(" " * cols)

        setpos(divider_line, 2)
        addstr(left_text.ljust(cols / 3))

        setpos(divider_line, cols / 3)
        addstr(center_text.center(cols / 3))

        setpos(divider_line, cols - right_text.size - 2)
        addstr(right_text)
      end
    end

    def visible_letters
      (@sx...max_cols + @sx).map { |col| @letters[col] }
    end

    def selected?(row, col)
      address.col == col && address.row == (@sy + row)
    end

    def draw_cells(padding: 4)
      1.upto(max_rows).each do |row|
        visible_letters.each.with_index do |col, index|
          setpos(row, padding + index * @col_width)

          if selected? row, col
            attron(color_pair(@mode == :edit ? COLOR_GREEN : COLOR_WHITE) | A_TOP) do
              draw_cell @sy + row, col
            end
          else
            cell_address = Address.new(col, @sy + row).to_sym

            if @show_dependencies && current_cell_dependencies.include?(cell_address)
              attron(color_pair(COLOR_CYAN) | A_LOW) do
                draw_cell @sy + row, col
              end
            elsif @show_dependencies && current_cell_dependents.include?(cell_address)
              attron(color_pair(COLOR_YELLOW) | A_LOW) do
                draw_cell @sy + row, col
              end
            else
              draw_cell @sy + row, col
            end
          end
        end
      end
    end

    def draw_letters_header(padding: 4, color: COLOR_BLUE)
      visible_letters.each.with_index do |letter, index|
        setpos(0, padding + index * @col_width)

        attron(color_pair(color) | A_TOP) do
          addstr(letter.center(@col_width))
        end
      end
    end

    def draw_numbers_header(padding: 4, color: COLOR_BLUE)
      1.upto(max_rows).each.with_index do |row, index|
        setpos(row, 0)

        attron(color_pair(COLOR_BLUE) | A_TOP) do
          addstr (@sy + row).to_s.rjust(padding)
        end
      end
    end

    def draw_cell(row, col)
      value = cell_value_at(Address.new(col, row))

      case value
        when Spreadshit::Window::ReferenceError
          addstr("#REF!".center(@col_width))
        when Spreadshit::Window::NameError
          addstr("#NAME?".center(@col_width))
        when Spreadshit::Window::ValueError
          addstr("#VALUE!".center(@col_width))
        when -> string { string.to_s.size > @col_width }
          addstr(value.to_s.chars.last(@col_width).join)
        else
          addstr(value.to_s.rjust(@col_width))
      end
    end

    def input_line
      lines - 1
    end

    def divider_line
      lines - 2
    end

    def cursor_to_input_line
      setpos(input_line, 2)
    end
  end
end
