require "curses"
require "ostruct"

class Window
  include Curses

  def initialize(spreadsheet)
    @spreadsheet = spreadsheet
    @mode = :navigation
    @x, @y = 0, 0
    @sx, @sy = 0, 0
    @col_width = 12
    @letters = ("A".."ZZZ").to_a
  end

  def start
    init_screen
    start_color
    init_pair(COLOR_WHITE, COLOR_BLACK, COLOR_WHITE)
    use_default_colors
    redraw

    loop { capture_input }
  end

  private

  def max_cols
    cols / @col_width
  end

  def max_rows
    lines - 4
  end

  def coords
    OpenStruct.new(x: @letters[@x], y: @y)
  end

  def current_cell
    @spreadsheet.cell_at("#{coords.x}#{coords.y + 1}")
  end

  def current_cell=(value)
    @spreadsheet["#{coords.x}#{coords.y + 1}"] = value
  end

  def capture_input
    case @mode
    when :navigation
      navigate
    when :edit
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
    else
      return
    end

    redraw
  end

  def read_cell_definition
    echo
    self.current_cell = getstr
    @mode = :navigation
    redraw
  end

  def redraw
    draw_text_field
    draw_cells
    cursor_to_input_line
    refresh
  end

  def draw_text_field
    setpos(divider_line, 0)

    attron(color_pair(COLOR_WHITE) | A_NORMAL) do
      case @mode
      when :navigation
        addstr(" Press ENTER to edit #{coords.x}#{coords.y + 1}" + " " * cols)
      when :edit
        addstr(" [Define value for #{coords.x}#{coords.y + 1}]" + " " * cols)
      end
    end

    case @mode
    when :navigation
      cursor_to_input_line
      addstr(" " + current_cell.raw.to_s)
      clrtoeol
    when :edit
      cursor_to_input_line
      clrtoeol
    end
  end

  def draw_cells
    col_number = 5

    (@sx..max_cols + @sx).each do |col|
      setpos(0, col_number)
      print_header @letters[col]
      col_number += @col_width
    end

    1.upto(max_rows).map do |row|
      col_number = 5

      setpos(row, 0)
      addstr("% 3s " % (@sy + row))

      (@sx..max_cols + @sx).map { |col| @letters[col] }.map do |col|
        setpos(row, col_number)

        if coords.x == col && coords.y == (@sy + row - 1)
          attron(color_pair(COLOR_WHITE) | A_NORMAL) do
            print_cell @sy + row, col
          end
        else
          print_cell @sy + row, col
        end

        col_number += @col_width
      end
    end
  end

  def print_cell(row, col)
    addstr("% #{@col_width}s" % @spreadsheet["#{col}#{row}"].to_s)
  end

  def print_header(letter)
    addstr("% #{@col_width / 2}s" % letter)
  end

  def input_line
    lines - 1
  end

  def divider_line
    lines - 2
  end

  def window_line_size
    lines - 2
  end

  def cursor_to_input_line
    setpos(input_line, 0)
  end
end
