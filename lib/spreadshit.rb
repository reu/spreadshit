require "matrix"

class Spreadshit
  class CyclicDependency < Struct.new(:address); end

  require "spreadshit/cell"
  require "spreadshit/formula"
  require "spreadshit/functions"

  def initialize(parser = Formula.new, functions = Functions.new)
    @cells = Hash.new { |cells, address| cells[address] = Cell.new(address) }
    @parser = parser
    @functions = functions
  end

  def [](address)
    @cells[address.to_sym].value
  end

  def []=(address, value)
    @cells[address.to_sym].update(value) { parse(value) }
  end

  def raw(address)
    @cells[address.to_sym].raw
  end

  def cell(address)
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
    refs = cols.map do |col|
      rows.map { |row| Formula::Reference.new(col, row) }
    end

    Matrix[*refs].transpose
  end
end
