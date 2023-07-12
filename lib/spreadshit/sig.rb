require "set"

class Sig
  def initialize(&computation)
    @observers = Set.new
    @dependencies = Set.new
    @computation = computation || proc { nil }
    compute if block_given?
  end

  def value
    if caller
      @observers << caller
      caller.dependencies << self
    end
    @value
  end

  def update(&computation)
    @computation = computation
    compute
    @value
  end

  def depends_on?(other_sig)
    @dependencies.include? other_sig
  end

  def observed_by?(other_sig)
    @observers.include? other_sig
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
    :signal
  end
end
