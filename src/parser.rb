require_relative 'lib'

class Parser
  class ParseError < RuntimeError
  end

  def initialize(tokens)
    @tokens = tokens
    @current = 0
    @break_possible = false
  end

  def parse
    begin
      statements = []
      while !at_end? do
        statements.push(declaration)
      end
      statements
    rescue ParseError
      nil
    end
  end
  
  private

  def declaration
    begin
      if check(:fun) && check_next(:identifier)
        consume(:fun, nil)
        return function('function')
      end
      return var_declaration if match(:var) 
      statement
    rescue ParseError
      synchronize
      nil
    end
  end

  def var_declaration
    name = consume(:identifier, "Expect variable name.")
    initializer = nil
    if match(:equal)
      initializer = expression
    end

    consume(:semicolon, "Expect ';' after variable declaration")
    Stmt::Var.new(name, initializer)
  end

  def statement
    return for_statement if match(:for)
    return if_statement if match(:if)
    return while_statement if match(:while)
    return Stmt::Block.new(block) if match(:left_brace)
    return print_statement if match(:print)
    return return_statement if match(:return)
    return break_statement if check(:break)
      
    expression_statement
  end

  def for_statement
    consume(:left_paren, "Expect '(' after 'for'.")
    if match(:semicolon)
      initializer = nil
    elsif match(:var)
      initializer = var_declaration
    else
      initializer = expression_statement
    end

    if !check(:semicolon)
      condition = expression
    else
      condition = nil
    end
    consume(:semicolon, "Expect ';' after loop condition.")

    if !check(:right_paren)
      increment = expression
    else
      increment = nil
    end
    consume(:right_paren, "Expect ')' after for clauses.")

    @break_possible = true
    body = statement
    @break_possible = false

    unless increment.nil?
      body = Stmt::Block.new([body, Stmt::Expression.new(increment)])
    end

    if condition.nil?
      condition = Expr::Literal.new(true)
    end
    body = Stmt::While.new(condition, body)

    unless initializer.nil?
      body = Stmt::Block.new([initializer, body])
    end

    body
  end

  def while_statement
    consume(:left_paren, "Expect '(' after 'while'.")
    condition = expression
    consume(:right_paren, "Expect ')' after condition.")
    @break_possible = true
    body = statement
    @break_possible = false

    Stmt::While.new(condition, body)
  end

  def if_statement
    consume(:left_paren, "Expect '(' after 'if'.")
    condition = expression
    consume(:right_paren, "Expect ')' after 'if' condition.")
    then_branch = statement
    else_branch = nil
    if match(:else)
      else_branch = statement
    end

    Stmt::If.new(condition, then_branch, else_branch)
  end

  def print_statement
    value = expression
    consume(:semicolon, "Expect ';' after value.")
    Stmt::Print.new(value)
  end

  def return_statement
    keyword = previous
    value = nil
    if !check(:semicolon)
      value = expression
    end

    consume(:semicolon, "Expect ';' after return value.")
    Stmt::Return.new(keyword, value)
  end

  def expression_statement
    expr = expression
    consume(:semicolon, "Expect ';' after expression.")
    Stmt::Expression.new(expr)
  end

  def function(kind)
    name = consume(:identifier, "Expect #{kind} name.")
    
    Stmt::Function.new(name, function_body(kind))
  end

  def function_body(kind)
    consume(:left_paren, "Expect '(' after #{kind} name.")
    parameters = []
    if !check(:right_paren)
      loop do
        if parameters.size >= 255
          error(peek, 'Cannot have more than 255 parameters')
        end
        parameters << consume(:identifier, 'Expect parameter name.')
        break unless match(:comma)
      end
    end
    consume(:right_paren, "Expect ')' after parameters.")
    consume(:left_brace, "Expect '{' before #{kind} body.")
    body = block
    Expr::Function.new(parameters, body)
  end

  def block
    statements = []

    while !check(:right_brace) && !at_end? do
      statements << declaration
    end

    consume(:right_brace, "Expect '}' after block.")
    statements
  end

  def break_statement
    if !@break_possible
      raise error(peek, "Break statement not allowed outside a loop.")
    end
    consume(:break, "Break statement expected.")
    consume(:semicolon, "Expect ';' after 'break'.")

    @break_possible = false
    Stmt::Break.new(nil)
  end

  def expression
    assignment
  end

  def assignment
    expr = or_expr

    if match(:equal)
      equals = previous
      value = assignment
      if expr.is_a?(Expr::Variable)
        name = expr&.name
        return Expr::Assign.new(name, value)
      end

      error(equals, "Invalid assignment target.")
    end

    expr
  end

  def or_expr
    expr = and_expr

    while match(:or) do
      operator = previous
      right = and_expr
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  def and_expr
    expr = equality

    while match(:and) do
      operator = previous
      right = equality
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  def equality
    expr = comparison

    while match(:bang_equal, :equal_equal) do
      operator = previous
      right = comparison
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def comparison
    expr = addition

    while match(:greater, :greater_equal, :less, :less_equal)  do
      operator = previous
      right = addition
      expr = Expr::Binary.new(expr, operator, right)
    end
    
    expr
  end

  def addition
    expr = multiplication

    while match(:minus, :plus) do
      operator = previous
      right = multiplication
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def multiplication
    expr = unary

    while match(:slash, :star) do
      operator = previous
      right = unary
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  def unary
    if match(:bang, :minus)
      operator = previous
      right = unary
      return Expr::Unary.new(operator, right)
    end

    call
  end

  def call
    expr = primary
    
    loop do
      if match(:left_paren)
        expr = finish_call(expr)
      else
        break
      end
    end

    expr
  end

  def finish_call(callee)
    arguments = []
    if !check(:right_paren)
      loop do
        if arguments.size >= 255
          error(peek, "Cannot have more than 255 arguments.")
        end
        arguments << expression
        break unless match(:comma)
      end
    end
    
    paren = consume(:right_paren, "Expect ')' after arguments.")
    Expr::Call.new(callee, paren, arguments)
  end

  def primary
    return Expr::Literal.new(false) if match(:false)
    return Expr::Literal.new(true) if match(:true)
    return Expr::Literal.new(nil) if match(:nil)

    return function_body('function') if match(:fun)

    if match(:number, :string)
      return Expr::Literal.new(previous.literal)
    end

    if match(:identifier)
      return Expr::Variable.new(previous)
    end

    if match(:left_paren)
      expr = expression
      consume(:right_paren, "Expect ')' after expression.")
      return Expr::Grouping.new(expr)
    end

    raise error(peek, 'Expect expression.')
  end

  def consume(type, message)
    return advance if check(type)

    raise error(peek, message)
  end

  def error(token, message)
    Lox.error(token, message)
    return ParseError.new
  end

  def synchronize
    advance

    while !at_end?
      return if previous.type == :semicolon

      case peek.type
      when :class
      when :fun
      when :var
      when :for
      when :if
      when :while
      when :print
      when :return
        return
      end
    advance
    end
  end

  def match(*types)
    types.each do |type|
      if check(type)
        advance
        return true
      end
    end

    false
  end

  def check(type)
    return false if at_end?
    peek.type == type
  end

  def check_next(type)
    return false if at_end?
    return false if @tokens[@current+1].type == :eof
    return @tokens[@current+1].type == type
  end

  def advance
    @current += 1 if !at_end?
    previous
  end

  def at_end?
    peek.type == :eof
  end

  def peek
    @tokens[@current]
  end

  def previous
    @tokens[@current-1]
  end

end