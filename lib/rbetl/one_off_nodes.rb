require 'rbetl/etl_node'
require 'json'
require 'methadone'

module Rbetl
  class JsonTable < EtlNode
    include Methadone::CLILogging
    def publish
      pub = {}
      until (lines = get).nil?
        if lines.respond_to? :each
          re = /CREATE TABLE \"(\w+)/
          match = re.match(lines[0])
          if match.nil?
            error("Class Rbetl::JsonTable is looking for a first line with CREATE_TABLE")
          else
            key = match[1]
            value = []
            lines.each do |line|
              value << line
            end
            pub[key] = value
          end
        else
          error("Class JsonTable is looking for groups of lines that make up one table")
        end
      end
      puts JSON.generate(pub)
    end
  end
end