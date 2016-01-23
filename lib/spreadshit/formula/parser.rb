require "treetop"

class Spreadshit
  module Formula
    class Parser
      module Nodes
        class Node < Treetop::Runtime::SyntaxNode; end
        class NumberNode < Node; end
        class StringNode < Node; end
        class GroupNode < Node; end
        class FunctionNode < Node; end
        class ArgumentListNode < Node; end
        class AdditiveNode < Node; end
        class MultiplicativeNode < Node; end
        class RangeNode < Node; end
        class ReferenceNode < Node; end
      end

      def initialize
        @parser = Treetop.load(File.join(File.dirname(__FILE__), "parser.treetop")).new
        @cache = {}
      end

      def parse(string)
        @cache[string] ||= process(@parser.parse(string))
      end

      def process(node)
        case node
        when Nodes::NumberNode
          node.text_value.include?(".") ?
            Decimal.new(node.text_value.to_f) :
            Integer.new(node.text_value.to_i)

        when Nodes::StringNode
          String.new(node.chars.text_value)

        when Nodes::GroupNode
          process node.content

        when Nodes::FunctionNode
          Function.new(
            node.name.text_value.upcase,
            process(node.arguments) || []
          )

        when Nodes::ArgumentListNode
          if node.tail.elements.empty?
            [process(node.head)]
          else
            [process(node.head)] + process(node.tail.elements[0].arguments)
          end

        when Nodes::RangeNode
          Range.new(process(node.top), process(node.bottom))

        when Nodes::ReferenceNode
          Reference.new(node.col.text_value.upcase, node.row.text_value.to_i)

        when Nodes::AdditiveNode
          if node.tail.elements.empty?
            process node.head
          else
            node.tail.elements.reduce(process(node.head)) do |left, node|
              right = process(node.operand)
              case node.operator.text_value
                when "+" then Addition.new(left, right)
                when "-" then Subtraction.new(left, right)
              end
            end
          end

        when Nodes::MultiplicativeNode
          if node.tail.elements.empty?
            process node.head
          else
            node.tail.elements.reduce(process(node.head)) do |left, node|
              right = process(node.operand)
              case node.operator.text_value
                when "*" then Multiplication.new(left, right)
                when "/" then Division.new(left, right)
              end
            end
          end
        end
      end
    end
  end
end
