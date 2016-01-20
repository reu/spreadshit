class Spreadshit::Cell
  attr_reader :address, :raw

  def initialize(address, &expression)
    @address = address
    @observers = Set.new
    @dependencies = []
    update(&expression) if block_given?
  end

  def value
    if @@caller
      @observers << @@caller
      @@caller.dependencies << self
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
