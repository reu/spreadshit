class Spreadshit
  require "spreadshit/cell"
  require "spreadshit/cycle_detector"
  require "spreadshit/formula"
  require "spreadshit/functions"

  def initialize(parser: Formula::Parser.new, functions: Functions.new, cycle_detector: CycleDetector.new)
    @cells = Hash.new { |cells, address| cells[address] = Cell.new(address, Formula::Literal.new(nil)) }
    @parser = parser
    @functions = functions
    @cycle_detector = cycle_detector
  end

  def [](address)
    @cells[address.to_sym].value
  end

  def []=(address, value)
    address = address.to_sym
    content = parse value

    @cycle_detector[address] = content.references
    @cells[address].update(content) do
      if cyclic_reference = cycle(address)
        # TODO: this is bullshit...
        (content.references - [cyclic_reference]).each { |a| self[a] }

        Formula::CyclicDependency.new(cyclic_reference)
      elsif content.is_a? Formula::Error
        content
      else
        eval content
      end
    end
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
      begin
        @parser.parse(value[1..-1])
      rescue Formula::Parser::UnparseableFormula => error
        Formula::InvalidFormula.new(error.input)
      end
    else
      Formula::Literal.new(value)
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
      expression.to_matrix.map { |ref| eval ref }
    end
  end

  def cycle(address)
    @cycle_detector.cycle(address)
  end
end
