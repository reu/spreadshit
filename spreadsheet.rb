require "./formula"
require "./functions"

class Spreadsheet
  def initialize(parser = Formula.new, functions = Functions.new)
    @cells = Hash.new { |hash, key| hash[key] = Cell.new }
    @parser = parser
    @functions = functions
  end

  def [](address)
    @cells[address.to_sym].value
  end

  def []=(address, value)
    @cells[address.to_sym].update(value) { parse(value) }
  end

  def cell_at(address)
    @cells[address.to_sym]
  end

  private

  def parse(value)
    if value.to_s.start_with? "="
      eval @parser.parse(value[1..-1])
    else
      value
    end
  end

  def eval(expression)
    case expression
    when Formula::Literal
      expression.content
    when Formula::Addition
      @functions.add(eval(expression.left), eval(expression.right))
    when Formula::Subtraction
      @functions.minus(eval(expression.left), eval(expression.right))
    when Formula::Multiplication
      @functions.multiply(eval(expression.left), eval(expression.right))
    when Formula::Division
      @functions.divide(eval(expression.left), eval(expression.right))
    when Formula::Function
      @functions.send(expression.name.downcase, *expression.arguments.map { |arg| eval arg })
    when Formula::Reference
      self[expression.address]
    when Formula::Range
      expand_range(expression.top, expression.bottom).map { |ref| eval ref }
    end
  end

  def expand_range(top, bottom)
    cols = top.col..bottom.col
    rows = top.row..bottom.row
    cols.flat_map do |col|
      rows.map { |row| Formula::Reference.new(col, row) }
    end
  end
end

class Cell
  attr_reader :raw

  def initialize(raw = "", &expression)
    @raw = raw
    @observers = Set.new
    @observed = []
    update(&expression) if block_given?
  end

  def value
    if @@caller
      @observers << @@caller
      @@caller.observed << self
    end
    @value
  end

  def update(value = raw || "", &expression)
    @raw = value
    @expression = expression
    compute
    @value
  end

  protected

  attr_reader :observers, :observed

  def compute
    @observed.each { |observed| observed.observers.delete(self) }
    @observed = []

    @@caller = self
    new_value = @expression.call
    @@caller = nil

    if new_value != @value
      @value = new_value
      observers = @observers
      @observers = Set.new
      observers.each { |observer| observer.compute }
    end
  end
end
