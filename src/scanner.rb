require_relative 'lib'

class Scanner
  @@Keywords = {'and' => :and, 'break' => :break, 'class' => :class, 'else' => :else,
    'false' => :false, 'for' => :for, 'fun' => :fun, 'if' => :if,
    'nil' => :nil, 'or' => :or, 'print' => :print, 'return' => :return,
    'super' => :super, 'this' => :this, 'true' => :true, 'var' => :var, 'while' => :while}

  def initialize(source)
    @source = source
    @tokens = []
    @start = 0
    @current = 0
    @line = 1
  end

  def scan_tokens()
    while !at_end? do
      @start = @current
      scan_token
    end
    @tokens.push(Token.new(:eof, '', nil, @line))
    return @tokens
  end

  private 

  def scan_token
    c = advance
    case c
    when '('
      add_token(:left_paren)
    when ')'
      add_token(:right_paren)
    when '{'
      add_token(:left_brace)
    when '}'
      add_token(:right_brace)
    when ','
      add_token(:comma)
    when '.'
      add_token(:dot)
    when '-'
      add_token(:minus)
    when '+'
      add_token(:plus)
    when ';'
      add_token(:semicolon)
    when '*'
      add_token(:star)
    when '!'
      add_token(match('=') ? :bang_equal : :bang)
    when '='
      add_token(match('=') ? :equal_equal : :equal)
    when '<'
      add_token(match('=') ? :less_equal : :less)
    when '>'
      add_token(match('=') ? :greater_equal : :greater)
    when '/'
      if match('/')
        while peek != "\n" && !at_end? do
          advance
        end
      else
        add_token(:slash)
      end
    when ' ', "\r", "\t"
    when "\n"
      @line += 1
    when '"'
      string
    else
      if is_digit(c)
        number
      elsif is_alpha(c)
        identifier
      else
        Lox.error(@line, 'Unexpected character.')
      end
    end
  end

  def is_digit(c)
    return c >= '0' && c <= '9'
  end

  def is_alpha(c)
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
           c == '_'
  end

  def is_alpha_numeric(c)
    return is_alpha(c) || is_digit(c)
  end

  def number
    while is_digit(peek) do
      advance
    end
    if peek == '.' && is_digit(peek_next)
      advance
      while is_digit(peek) do
        advance
      end
    end
    add_token(:number, @source[@start..@current-1].to_f)
  end

  def string
    while peek != '"' && !at_end? do
      if peek == '\n'
        @line += 1
      end
      advance
    end

    if at_end?
      Lox.error(@line, 'Unterminated string.')
      return
    end

    advance

    value = @source[@start+1..@current-2]
    add_token(:string, value)
  end

  def advance
    @current += 1
    @source[@current-1]
  end

  def add_token(*args)
    case args.size
    when 1
      type = args[0]
      literal = nil
    when 2
      type = args[0]
      literal = args[1]
    end

    text = @source[@start..@current-1]
    @tokens.push(Token.new(type, text, literal, @line))
  end

  def match(expected)
    return false if at_end?
    return false if @source[@current] != expected

    @current += 1
    true
  end
  
  def peek
    return '\0' if at_end?
    @source[@current]
  end

  def peek_next
    if @current+1 >= @source.length
      return '\0'
    end
    return @source[@current+1]
  end

  def identifier
    advance while is_alpha_numeric(peek)
    text = @source[@start..@current-1]
    type = @@Keywords[text]
    type = :identifier if type == nil
    add_token(type)
  end


  def at_end?
    @current >= @source.length
  end 
end