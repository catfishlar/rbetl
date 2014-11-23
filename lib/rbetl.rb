require "rbetl/version"

module Rbetl

  class StdIn

    def initialize
    end

    def get
      line = gets
      line = line.chomp  unless line.nil?
      return line
    end
  end

  class EtlNode

    def initialize(source=nil)
      if source.nil?
        source = StdIn.new
      end
      @source = source
    end

    def set_source(source)
      @source = source
    end

    #--------
    # your get is going to do some processing.
    # one thing it can do is collect a set of lines and return that
    # Array of lines up.  To do this override this function.
    #
    # if all you want to do is mod a single line then you can use this below:
    # The logic below keeps grabbing lines from its source
    # Until a non-nil line is emited by process
    #  All you have to do is override process and/or process_line
    def get
      val = @source.get
      return nil if val.nil?
      processed_val = process(val)
      if processed_val.nil?
        get
      else
        return processed_val
      end

    end

    def publish
      until (lines = get).nil?
        if lines.respond_to? :each
          lines.each do |line|
            publish_line(line)
          end
        else
          publish_line(lines)
        end
      end
    end


    #private

    def process(lines)
      if lines.respond_to? :each
        ret_lines = []
        lines.each do |line|
          ret = process_line(line)
          ret_lines << ret unless ret.nil?
        end
        if ret_lines.empty?
          return nil
        else
          return ret_lines
        end
      else
        process_line(lines)
      end
    end

    def process_line(line)
      return line
    end

    def publish_line(line)
      puts(line)
    end
  end

  class InputFile < EtlNode
    def initialize(filename=nil)
      @filename = filename
      @file = nil
    end

    def open_file(filename)
      @filename = filename
      @file = File.open(@filename, 'r')
    end

    def close_file
      @file.close unless @file.nil?
    end

    def get
      if @filename.nil?
        #Error
      else
        if @file.nil?
          @file = File.open(@filename, 'r')
          #Error?
        end
      end
      line = @file.gets
      line = line.chomp unless line.nil?
      return line
    end
  end

  class OutputFile < EtlNode
    def initialize(source, filename=nil)
      @source = source
      @filename = filename
      @file = nil
    end

    def open_file(filename=nil)
      @filename = filename unless filename.nil?
      @file = File.open(@filename, 'w')
    end

    def close_file
      @file.close unless @file.nil?
    end

    def publish
      if @file.nil?
        @file = open_file
      end
      super
      close_file
    end

    def publish_line(line)
      @file.puts(line)
    end
  end


  class PatternContext < EtlNode

    def initialize(source, pattern, after, compare)
      @source = source
      @pattern = pattern
      @after = after
      @compare = compare
    end

    #-------
    # overriding Get so that we grab a set of lines that start with the match and the follow on lines.
    def get
      match = nil
      ret_lines = []
      until match
        line = @source.get
        return nil if line.nil?
        if line.respond_to? :each
          error ('PatternContext::get is not designed to get arrays of lines from its source')
        end
        match = line if @compare.call(line,@pattern)
      end
      if  @after > 0
        ret_lines << match
        count = @after
        while count > 0
          line = @source.get
          if line.nil?
            count = 0
          else
            ret_lines << line
            # if you find the pattern in the context start the count over.
            @compare.call(line, @pattern) ? count = @after : count -= 1
          end
        end
        return ret_lines
      else
        return match
      end
    end
  end
  class PatternBetween < EtlNode

    def initialize(source, pattern1, pattern2, compare)
      @source = source
      @pattern1 = pattern1
      @pattern2 = pattern2
      @compare = compare
    end

    #-------
    # overriding Get so that we grab a set of lines that start with the match and the follow on lines.
    def get
      match = nil
      ret_lines = []
      until match
        line = @source.get
        return nil if line.nil?
        if line.respond_to? :each
          error ("PatternBetween::get is not designed to get arrays of lines from its source")
        end
        match = line if @compare.call(line,@pattern1)
      end
      ret_lines << match
      #and all lines till the other match
      begin
        line = @source.get
        ret_lines << line unless line.nil?
      end until line.nil? || @compare.call(line,@pattern2)
      return ret_lines
    end

  end
  class CombineLines < EtlNode

    def initialize(source, seperator)
      @source = source
      @seperator = seperator
    end

    #-------
    # overriding Get so we can join any arrays of strings with the seperator
    def get
      lines = @source.get
      if lines.respond_to? :each
        lines = lines.join(@seperator)
      end
      return lines
    end

  end

end
