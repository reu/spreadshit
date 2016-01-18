class Functions
  [[:+, :add], [:-, :subtract], [:*, :multiply], [:/, :divide]].each do |operator, name|
    define_method(name) { |left, right| to_number(left).send(operator, to_number(right)) }
  end

  def sum(*args)
    to_number args.flatten.map { |arg| to_number(arg) }.reduce(:+)
  end

  def date(year, month, date)
    Date.new(year, month, date)
  end

  private

  def to_number(value)
    if value.to_f - value.to_i == 0
      value.to_i
    else
      value.to_f
    end
  end
end
