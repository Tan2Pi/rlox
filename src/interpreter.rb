require_relative 'lib'

class Interpreter
  attr_accessor :globals

  class BreakRescue < RuntimeError
  end

  def initialize
    @globals = Environment.new
    @globals.define('clock', LoxCallable.new do 
        def arity
          0
        end
        def call
          Time.now.to_i
        end
        def to_s
          '<native fn>'
        end
      end
    )
    @environment = @globals
    @locals = Hash.new
  end

  def interpret(statements)
    begin
      statements.each do |statement|
        execute(statement)
      end
    rescue LoxRuntimeError => error
      Lox.runtime_error(error)
    end
  end

  def resolve(expr, depth)
    @locals[expr] = depth
  end

  def visit_if_statement(stmt)
    if truthy?(evaluate(stmt.condition))
      execute(stmt.then_branch)
    elsif !stmt.else_branch.nil?
      execute(stmt.else_branch)
    end
    nil
  end

  def visit_var_statement(stmt)
    value = nil
    unless stmt.initializer.nil?
      value = evaluate(stmt.initializer)
    end

    @environment.define(stmt.name.lexeme, value)
    nil
  end

  def visit_while_statement(stmt)
    begin
      while truthy?(evaluate(stmt.condition)) do
        execute(stmt.body)
      end
    rescue BreakRescue
    end 
    nil
  end

  def visit_assign_expr(expr)
    value = evaluate(expr.value)
    distance = @locals[expr]
    unless distance.nil?
      @environment.assign_at(distance, expr.name, value)
    else
      @globals.assign(expr.name, value)
    end
    
    value
  end

  def visit_expression_statement(stmt)
    evaluate(stmt.expression)
    nil
  end

  def visit_function_statement(stmt)
    function = LoxFunction.new(stmt.name.lexeme, stmt.function, @environment)
    @environment.define(stmt.name.lexeme, function)
    nil
  end

  def visit_print_statement(stmt)
    value = evaluate(stmt.expression)
    puts stringify(value)
    nil
  end

  def visit_return_statement(stmt)
    value = nil
    unless stmt.value.nil?
      value = evaluate(stmt.value)
    end
    raise Return.new(value);
  end

  def visit_break_statement(stmt)
    raise BreakRescue.new
  end

  def visit_block_statement(stmt)
    execute_block(stmt.statements, Environment.new(@environment))
  end

  def execute_block(statements, environment)
    previous = @environment
    begin
      @environment = environment
      statements.each do |statement|
        execute(statement)
      end
    ensure
      @environment = previous
    end
  end

  def visit_function_expr(expr)
    function = LoxFunction.new(nil, expr, @environment)
  end

  def visit_grouping_expr(expr)
    evaluate(expr.expression)
  end

  def visit_literal_expr(expr)
    expr.value
  end

  def visit_logical_expr(expr)
    left = evaluate(expr.left)

    if expr.operator.type == :or
      return left if truthy?(left)
    else
      return left if !truthy?(left)
    end

    evaluate(expr.right)
  end

  def visit_unary_expr(expr)
    right = evaluate(expr.right)

    case expr.operator.type
    when :bang
      return !truthy?(right)
    when :minus
      check_number_operand(expr.operator, right)
      return -right
    end
  end

  def visit_variable_expr(expr)
    lookup_variable(expr.name, expr)
  end

  def lookup_variable(name, expr)
    distance = @locals[expr]
    unless distance.nil?
      return @environment.get_at(distance, name.lexeme)
    else
      return @globals.get(name)
    end
  end

  def visit_binary_expr(expr)
    left  = evaluate(expr.left)
    right = evaluate(expr.right)

    case expr.operator.type
    when :greater
      check_number_operands(expr.operator, left, right)
      return left > right
    when :greater_equal
      check_number_operands(expr.operator, left, right)
      return left >= right
    when :less
      check_number_operands(expr.operator, left, right)
      return left < right
    when :less_equal
      check_number_operands(expr.operator, left, right)
      return left <= right
    when :bang_equal
      return !equal?(left, right)
    when :equal_equal
      return equal?(left, right)
    when :minus
      check_number_operands(expr.operator, left, right)
      return left - right
    when :slash
      check_number_operands(expr.operator, left, right)
      raise LoxRuntimeError.new(expr.operator, "Cannot divide by zero.") if right == 0
      return left / right
    when :star
      check_number_operands(expr.operator, left, right)
      return left * right
    when :plus
      if left.is_a?(Float) && right.is_a?(Float)
        return left + right
      elsif left.is_a?(String) && right.is_a?(String)
        return left + right
      elsif left.is_a?(String)
        return left + stringify(right)
      elsif right.is_a?(String)
        return stringify(left) + right
      else
        raise LoxRuntimeError.new(expr.operator, "Invalid addition types (String(s) or Number(s)).")
      end 
    end
  end

  def visit_call_expr(expr)
    callee = evaluate(expr.callee)
    
    arguments = expr.arguments.map do |argument|
      evaluate(argument)
    end
    
    unless callee.is_a?(LoxCallable)
      raise LoxRuntimeError.new(expr.paren, "Can only call functions and classes")
    end

    function = callee
    if arguments.size != function.arity
      raise LoxRuntimeError.new(expr.paren, "Expected #{function.arity} arguments but found #{arguments.size}.")
    end
    function.call(self, arguments)
  end


  private

  def execute(stmt)
    stmt.accept(self)
  end

  def evaluate(expr)
    expr.accept(self)
  end

  def check_number_operand(operator, operand)
    unless operand.is_a?(Float)
      raise LoxRuntimeError.new(operator, "Operand must be a number")
    end
  end

  def check_number_operands(operator, left, right)
    unless (left.is_a?(Float) && right.is_a?(Float))
      raise LoxRuntimeError.new(operator, "Operands must be numbers.")
    end
  end

  def truthy?(object)
    if (object.nil? || object.is_a?(FalseClass)) then false else true end
  end

  def equal?(a, b)
    a == b
  end

  def stringify(object)
    if object.nil?
      "nil"
    elsif object.is_a?(Float)
      if object.to_s.end_with?('.0')
        object.to_i.to_s
      end
    else
      object.to_s
    end
  end
end