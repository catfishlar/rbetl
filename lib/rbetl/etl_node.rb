module Rbetl
  class Lines
    def initialize(lines)
      @lines = lines
      @cur_line_idx = 0
      @length = @lines.length
    end
    def get
      if @cur_line_idx < @length
        @cur_line_idx += 1
        @lines[@cur_line_idx-1]
      else
        nil
      end
    end
  end
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
end