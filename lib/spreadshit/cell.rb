class Spreadshit::Cell
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
