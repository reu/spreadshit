require "./formula"

module Functions
  def sum(*args)
    args.reduce(:+)
  end

  def date(year, month, date)
    Date.new(year, month, date)
  end
end

class Spreadsheet
  def initialize(parser = Formula.new)
    @cells = Hash.new { |hash, key| hash[key] = Cell.new }
    @parser = parser
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

  include Functions

  def parse(value)
    if value.to_s.start_with? "="
      eval @parser.parse(value[1..-1])
    else
      value
    end
  end

  def eval(expression)
    case expression
    when Formula::Addition
      eval(expression.left) + eval(expression.right)
    when Formula::Subtraction
      eval(expression.left) - eval(expression.right)
    when Formula::Multiplication
      eval(expression.left) * eval(expression.right)
    when Formula::Division
      eval(expression.left) / eval(expression.right)
    when Formula::Function
      send(expression.name.downcase, *expression.arguments.map { |arg| eval arg })
    when Formula::Reference
      self[expression.address]
    else
      expression
    end
  end
end

class Cell
  attr_reader :raw

  def initialize(raw = "", &expression)
    @raw = raw
    @observers = Set.new
    @observed = []

    if block_given?
      update(&expression)
    else
      update {}
    end
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
