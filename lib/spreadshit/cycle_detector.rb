require "tsort"

class Spreadshit
  class CycleDetector
    include TSort

    def initialize
      @graph = {}
    end

    def []=(address, references)
      @graph[address.to_sym] = references.map(&:to_sym)
    end

    def cycle(address)
      address = address.to_sym
      return address if @graph[address].include? address

      each_strongly_connected_component_from(address) do |components|
        return components.delete_if { |n| Array === n }.last if components.length != 1
      end
      nil
    end

    private

    def tsort_each_node(&block)
      @graph.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @graph.fetch(node, []).each(&block)
    end
  end
end
