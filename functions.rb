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
    case value
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
    when String
      if value.strip.empty?
        0
      else
        Float::NAN
      end
    else
      Float::NAN
    end
  end
end
