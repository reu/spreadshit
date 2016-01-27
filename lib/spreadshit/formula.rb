require "spreadshit/formula/parser"
require "matrix"

class Spreadshit
  module Formula
    module Travarsable
      include Enumerable

      def children
        []
      end

      def each(&block)
        block.call self
        children.each { |child| child.each(&block) }
      end

      def references
        find_all { |expression| expression.is_a? Reference }.to_set
      end
    end

    module Error
      def to_s
        ""
      end
    end

    class CyclicDependency < Struct.new(:address)
      include Travarsable
      include Error
    end

    class InvalidFormula < Struct.new(:formula)
      include Travarsable
      include Error
    end

    class Literal < Struct.new(:content)
      include Travarsable

      def to_s
        content.to_s
      end
    end

    class String < Literal; end
    class Number < Literal; end
    class Integer < Number; end
    class Decimal < Number; end

    class BinaryOperation < Struct.new(:left, :right)
      include Travarsable

      def children
        [left, right]
      end

      def to_s
        [left.to_s, right.to_s].join(" #{operator} ")
      end

      def operator
        fail NotImplementedError
      end
    end

    class Additive < BinaryOperation; end

    class Addition < Additive
      def operator
        :+
      end
    end

    class Subtraction < Additive
      def operator
        :-
      end
    end

    class Multiplicative < BinaryOperation
      def to_s
        if left.is_a? Additive
          ["(#{left})", right.to_s].join(" #{operator} ")
        elsif right.is_a? Additive
          [left.to_s, "(#{right})"].join(" #{operator} ")
        else
          super
        end
      end
    end

    class Multiplication < Multiplicative
      def operator
        :*
      end
    end

    class Division < Multiplicative
      def operator
        :/
      end
    end

    class Function < Struct.new(:name, :arguments)
      include Travarsable

      def children
        arguments
      end

      def to_s
        "#{name}(#{arguments.map(&:to_s).join(", ")})"
      end
    end

    class Reference < Struct.new(:col, :row)
      include Travarsable

      def address
        [col, row].join
      end

      def to_s
        address
      end

      def to_sym
        address.to_sym
      end
    end

    class Range < Struct.new(:top, :bottom)
      include Travarsable

      def to_s
        [top.address, bottom.address].join(":")
      end

      def to_matrix
        cols = top.col..bottom.col
        rows = top.row..bottom.row
        refs = cols.map do |col|
          rows.map { |row| Reference.new(col, row) }
        end

        Matrix[*refs].transpose
      end

      def children
        to_matrix.to_a.flatten
      end
    end
  end
end
