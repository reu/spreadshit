class Spreadshit::Cell
  attr_reader :address, :expression

  def initialize(address, expression)
    @address = address
    @expression = expression
    @signal = Sig.new
  end

  def value
    @signal.value
  end

  def update(expression, &computation)
    @expression = expression
    @signal.update(&computation)
  end

  def raw
    @expression.to_s
  end
end
