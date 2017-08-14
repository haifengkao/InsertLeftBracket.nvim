class Lexer
  include Enumerable
  def initialize
    @label   = nil
    @pattern = nil
    @handler = nil
    @input   = nil
    
    reset
    
    yield self if block_given?
  end
  
  def input(&reader)
    if @input.is_a? self.class
      @input.input(&reader)
    else
      class << reader
        alias_method :next, :call
      end
      
      @input = reader
    end
  end
  
  def add_token(label, pattern, &handler)
    unless @label.nil?
      @input = clone
    end
    
    @label   = label
    @pattern = /(#{pattern})/
    @handler = handler || lambda { |label, match| [label, match] }
    
    reset
  end
  
  def next(peek = false)
    while @tokens.empty? and not @finished
      new_input = @input.next
      if new_input.nil? or new_input.is_a? String
        @buffer    += new_input unless new_input.nil?
        new_tokens =  @buffer.split(@pattern)
        while new_tokens.size > 2 or (new_input.nil? and not new_tokens.empty?)
          @tokens << new_tokens.shift
          @tokens << @handler[@label, new_tokens.shift] unless new_tokens.empty?
        end
        @buffer   = new_tokens.join
        @finished = true if new_input.nil?
      else
        separator, new_token = @buffer.split(@pattern)
        new_token            = @handler[@label, new_token] unless new_token.nil?
        @tokens.push( *[ separator,
                         new_token,
                         new_input ].select { |t| not t.nil? and t != "" } )
        reset(:buffer)
      end
    end
    peek ? @tokens.first : @tokens.shift
  end
  
  def peek
    self.next(true)
  end
  
  def each
    while token = self.next
      yield token
    end
  end
  
  private
  
  def reset(*attrs)
    @buffer   = String.new if attrs.empty? or attrs.include? :buffer
    @tokens   = Array.new  if attrs.empty? or attrs.include? :tokens
    @finished = false      if attrs.empty? or attrs.include? :finished
  end
end


class ObjcParser
    
    attr_reader :list
  def initialize(args)
    @list = args
  end
  
  def get_position
    return nil,nil if @list.empty?
    has_message = true

    a = @list.pop
    endings = [:close,:post_op,:at_string,:at_selector,:identifier]
    openings = [:open,:return,:control]

    if a.tt == :identifier && !@list.empty? && endings.include?(@list[-1].tt)
      insert_point = find_object_start
    else
      @list << a
    has_message = false unless methodList
      insert_point = find_object_start
    end
    return insert_point, has_message
  end
  
  def methodList
        old = Array.new(@list)

    a = selector_loop(@list)
    if !a.nil? && a.tt == :selector
      if file_contains_selector? a.text
        return true
      else
        internal = Array.new(@list)
        b = a.text
        until internal.empty?
          tmp = selector_loop(internal)
          return true if tmp.nil?
          b = tmp.text + b
          if file_contains_selector? b
            @list = internal
            return true
          end
        end
      end
    else
    end
@list = old
return false
  end
  
  def file_contains_selector?(methodName)
    return false

    # unimplemented
    #fileNames = ["#{ENV['TM_BUNDLE_SUPPORT']}/CocoaMethods.txt.gz"]
    #userMethods = "#{ENV['TM_PROJECT_DIRECTORY']}/.methods.TM_Completions.txt.gz"

    #fileNames += [userMethods] if File.exists? userMethods
    #candidates = []
    #fileNames.each do |fileName|
      #zGrepped = %x{zgrep ^#{e_sh methodName }[[:space:]] #{e_sh fileName }}
      #candidates += zGrepped.split("\n")
    #end

    #return !candidates.empty?
  end
  
  def selector_loop(l)
    until l.empty?
      obj = l.pop
      case obj.tt
      when :selector
        return obj
      when :close
        return nil if match_bracket(obj.text,l).nil?
      when :open
        return nil
      end
    end
    return nil
  end
  
  def match_bracket(type,l)
    partner = {"]"=>"[",")"=>"(","}"=>"{"}[type]
    up = 1
    until l.empty?
      obj = l.pop
      case obj.text
      when type
        up +=1
      when partner
        up -=1
      end
      return obj.beg if up == 0
    end
  end
  
  def find_object_start
    openings = [:operator,:selector,:open,:return,:control]
    until @list.empty? || openings.include?(@list[-1].tt)
      obj = @list.pop
      case obj.tt
      when :close
        tmp = match_bracket(obj.text, @list)
        b = tmp unless tmp.nil?
      when :star
        b, ate = eat_star(b,obj.beg)
        return b unless ate
      when :nil
        b = nil
      else
        b = obj.beg
      end
    end
    return b
  end

  def eat_star(prev, curr)
    openings = [:operator,:selector,:open,:return,:control,:star]
    if @list.empty? || openings.include?(@list[-1].tt)
      return curr, true
    else
      return prev, false
    end
  end
end

def e_sn(arr)
  if arr
    return arr
  else 
    return ""
  end
end

# given a buffer and current cursor position, return the complete line of code
# based on ";" and indent (if the method call includes a block, ";" will fail)

class BracketAdder
  A = Struct.new(:tt, :text, :beg)

  def initialize
  end

  # given a string, add right bracket at cursor position and the corresponding left bracket if it is missing
  def addMissingBracket(line, caret_placement)
    res = line

    up = 0
    pat = /"(?:\\.|[^"\\])*"|\[|\]/
      line.scan(pat).each do |item|
         case item
         when "["
           up+=1
         when "]"
           up -=1
         end
       end
    if caret_placement ==-1
      res = "]$0" + e_sn(line[caret_placement+1..-1])
      return res
    end

    if up != 0 
      res = e_sn(line[0..caret_placement])+"]$0"+e_sn(line[caret_placement+1..-1])
      return res
    end
    
    to_parse = StringIO.new(line[0..caret_placement])
    
    print "to_parse: " + line[0..caret_placement] + "\n"
    lexer = Lexer.new do |l|
      l.add_token(:return,  /\breturn\b/)
      l.add_token(:nil, /\bnil\b/)
      l.add_token(:control, /\b(?:if|while|for|do)(?:\s*)\(/)# /\bif|while|for|do(?:\s*)\(/)
      l.add_token(:at_string, /"(?:\\.|[^"\\])*"/)
      l.add_token(:selector, /\b[A-Za-z_0-9]+:/)
      l.add_token(:identifier, /\b[A-Za-z_0-9]+\b/)
      l.add_token(:bind, /(?:->)|\./)
      l.add_token(:post_op, /\+\+|\-\-/)
      l.add_token(:at, /@/)
      l.add_token(:star, /\*/)
      l.add_token(:close, /\)|\]|\}/)
      l.add_token(:open, /\(|\[|\{/)
      l.add_token(:operator,   /[&-+\/=%!:\,\?;<>\|\~\^]/)

      l.add_token(:terminator, /;\n*|\n+/)
      l.add_token(:whitespace, /\s+/)
      l.add_token(:unknown,    /./) 
      
      l.input { to_parse.gets }
    end

    offset = 0
    tokenList = []

    lexer.each do |token| 
      tokenList << A.new(*(token<<offset)) unless [:whitespace,:terminator].include? token[0]
      offset +=token[1].length
    end
    if tokenList.empty?
      res = e_sn(line[0..caret_placement])+"]$0"+e_sn(line[caret_placement+1..-1])
      return res
    end
    
    print "tokenList: " + tokenList.join(",") + "\n"

    par = ObjcParser.new(tokenList)
    b, has_message = par.get_position

    #print "b: " + b
    #b should be nil, because no method should be inserted

    if !line[caret_placement+1].nil? && line[caret_placement+1].chr == "]"
      if b.nil? || par.list.empty? || par.list[-1].text == "["
          res = e_sn(line[0..caret_placement])+"]$0"+e_sn(line[caret_placement+2..-1])
          return res
      end
    end

    if b.nil?
      res = e_sn(line[0..caret_placement])+"]$0"+e_sn(line[caret_placement+1..-1])
    elsif !has_message && (b < caret_placement )
      res = e_sn(line[0..b-1]) unless b == 0
      ins = (/\s/ =~ line[caret_placement].chr ? "$0]" : " $0]")
      res += "[" +e_sn(line[b..caret_placement]) + ins +e_sn(line[caret_placement+1..-1])
    elsif b < caret_placement    
      if b == 0
        res = ""
      else
        res = e_sn(line[0..b-1]) unless b == 0
      end
      res += "[" +e_sn(line[b..caret_placement]) +"]$0"+e_sn(line[caret_placement+1..-1]) 
    else
      res = e_sn(line[0..caret_placement])+"]$0"+e_sn(line[caret_placement+1..-1])
    end
    return res
  end
end

if __FILE__ == $PROGRAM_NAME
  require "stringio"
  #line = "aaa bb"
  #caret_placement = 6
  #
  line = "[bb cc]; [aaa bb] cc"
  caret_placement = 19

  adder = BracketAdder.new
  puts adder.addMissingBracket(line, caret_placement)

  line = "aaa bb"
  caret_placement = 6
  puts adder.addMissingBracket(line, caret_placement)

  line = "[aaa bb"
  caret_placement = 6
  puts adder.addMissingBracket(line, caret_placement)

  line = "aaa block:^{\nreturn [cc dd];\n}"
  caret_placement = 31
  puts adder.addMissingBracket(line, caret_placement)

end
