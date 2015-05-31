require 'rbetl/etl_node'
require 'json'
require 'methadone'

module Rbetl
  class JsonInput <EtlNode
    def initialize(filename)
      f = File.open(filename).readlines.reduce(:+)
      @json_text = JSON.parse(f)
      @stack = [@json_text]

    end
    def get
      context = @stack.pop
      ctx_class = context.class
      if ctx_class == NilClass
        return nil

      elsif ctx_class == Hash
        val =  ['{',context.keys]
        if context.keys.length > 0
          @stack.push context, context[context.keys[0]]
        end
        return val

      elsif ctx_class == Array
        val = ['[',context.length]
        if context.length >0
          @stack.push context, context[0]
        end
        return val

      else
        return [ctx_class.to_s, context]
      end
    end
  end

end