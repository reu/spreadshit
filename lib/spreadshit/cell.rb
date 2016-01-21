class Spreadshit::Cell
  attr_reader :address, :raw

  def initialize(address, &expression)
    @address = address
    @observers = Set.new
    @dependencies = []
    update(&expression) if expression
  end

  def value
    if caller
      @observers << caller
      caller.dependencies << self
      return Spreadshit::CyclicDependency.new(address) if caller.observers.include? self
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

  attr_reader :observers, :dependencies

  def compute
    @dependencies.each { |dependencies| dependencies.observers.delete(self) }
    @dependencies = []

    new_value = storing_caller { @expression.call }

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
