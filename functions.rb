class Functions
  [[:+, :add], [:-, :minus], [:*, :multiply]].each do |operator, name|
    define_method(name) { |left, right| to_number(left).send(operator, to_number(right)) }
  end

  def divide(left, right)
    right = to_number(right)
    return Float::NAN if right.zero?
    to_number(to_number(left) / right.to_f)
  end

  def sum(*args)
    to_number args.flatten.map { |arg| to_number(arg) }.reduce(:+)
  end

  def average(*args)
    to_number(sum(*args) / args.size.to_f)
  end

  def sqrt(number)
    Math.sqrt to_number(number)
  end

  def ln(number)
    Math.log to_number(number)
  end

  def date(year, month, date)
    Date.new(year, month, date)
  end

  private

  def to_number(value)
    case value
    when Float::INFINITY
      value
    when nil
      0
    when Numeric
      if !value.to_f.nan? && value.to_f - value.to_i == 0
        value.to_i
      else
        value.to_f
      end
    when Date
      value
    when -> string { string.to_s =~ /\A[-+]?([0-9]+\.)?[0-9]+\z/ }
      to_number(value.to_f)
    when String && -> string { string.strip.empty? }
      0
    else
      Float::NAN
    end
  end
end
