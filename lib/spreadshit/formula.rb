require "spreadshit/formula/parser"

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

    class Literal < Struct.new(:content)
      include Travarsable
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
    end

    class Addition < BinaryOperation; end
    class Subtraction < BinaryOperation; end
    class Multiplication < BinaryOperation; end
    class Division < BinaryOperation; end

    class Function < Struct.new(:name, :arguments)
      include Travarsable

      def children
        arguments
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
