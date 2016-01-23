require "spreadshit/formula/parser"

class Spreadshit
  module Formula
    class Literal < Struct.new(:content); end
    class String < Literal; end
    class Number < Literal; end
    class Integer < Number; end
    class Decimal < Number; end

    class BinaryOperation < Struct.new(:left, :right); end
    class Addition < BinaryOperation; end
    class Subtraction < BinaryOperation; end
    class Multiplication < BinaryOperation; end
    class Division < BinaryOperation; end
    class Function < Struct.new(:name, :arguments); end

    class Reference < Struct.new(:col, :row)
      def address
        [col, row].join
      end

      def to_s
        address
      end
    end

    class Range < Struct.new(:top, :bottom)
      def to_s
        [top.address, bottom.address].join(":")
      end
    end
  end
end
