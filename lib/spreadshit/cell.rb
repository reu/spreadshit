class Spreadshit::Cell
  attr_reader :address, :expression

  def initialize(address, expression)
    @address = address
    @expression = expression
    @observers = Set.new
    @dependencies = Set.new
  end

  def value
    if caller
      @observers << caller
      caller.dependencies << self
    end
    @value
  end

  def update(expression, &computation)
    @expression = expression
    @computation = computation
    compute
    @value
  end

  def raw
    @expression.to_s
  end

  protected

  attr_reader :observers, :dependencies

  def compute
    @dependencies.each { |dependencies| dependencies.observers.delete(self) }
    @dependencies = Set.new

    new_value = storing_caller { @computation.call }

    if new_value != @value
      @value = new_value
      observers = @observers
      @observers = Set.new
      observers.each { |observer| observer.compute }
    end
  end

  private

  def caller
    Thread.current[thread_var]
  end

  def storing_caller
    Thread.current[thread_var] = self
    result = yield
  ensure
    Thread.current[thread_var] = nil
    result
  end

  def thread_var
    :spreadshit_caller_cell
  end
end
