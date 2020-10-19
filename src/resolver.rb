require_relative 'lib'

class Resolver
  def initialize(interpreter)
    @interpreter = interpreter
    @scopes = []
    @current_function = :none
  end

  def visit_block_statement(stmt)
    begin_scope
    resolve_all(stmt.statements)
    end_scope
    nil
  end

  def visit_expression_statement(stmt)
    resolve(stmt.expression)
    nil
  end

  def visit_function_statement(stmt)
    declare(stmt.name)
    define(stmt.name)

    resolve_function(stmt, :function)
    nil
  end

  def visit_if_statement(stmt)
    resolve(stmt.condition)
    resolve(stmt.then_branch)
    resolve(stmt.else_branch) unless stmt.else_branch.nil?
    nil
  end

  def visit_print_statement(stmt)
    resolve(stmt.expression)
    nil
  end

  def visit_return_statement(stmt)
    if @current_function == :none
      Lox.error(stmt.keyword, 'Cannot return from top-level code.')
    end
    resolve(stmt.value) unless stmt.value.nil?
    nil
  end

  def visit_var_statement(stmt)
    declare(stmt.name)
    unless stmt.initializer.nil?
      resolve(stmt.initializer)
    end
    define(stmt.name)
    nil
  end

  def visit_while_statement(stmt)
    resolve(stmt.condition)
    resolve(stmt.body)
    nil
  end

  def visit_assign_expr(expr)
    resolve(expr.value)
    resolve_local(expr, expr.name)
    nil
  end

  def visit_binary_expr(expr)
    resolve(expr.left)
    resolve(expr.right)
    nil
  end

  def visit_call_expr(expr)
    resolve(expr.callee)
    expr.arguments.each do |arg|
      resolve(arg)
    end
    nil
  end

  def visit_grouping_expr(expr)
    resolve(expr.expression)
    nil
  end

  def visit_literal_expr(expr)
    nil
  end

  def visit_logical_expr(expr)
    resolve(expr.left)
    resolve(expr.right)
    nil
  end

  def visit_unary_expr(expr)
    resolve(expr.right)
    nil
  end

  def visit_variable_expr(expr)
    if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
      Lox.error(expr.name, 'Cannot read local variable in its own initializer.')
    end

    resolve_local(expr, expr.name)
    nil
  end

  def resolve_all(statements)
    statements.each do |statement|
      resolve(statement)
    end
  end

  def resolve(obj)
    obj.accept(self)
  end

  def resolve_function(stmt, type)
    enclosing_function = @current_function
    @current_function = type

    begin_scope
    stmt.function.parameters.each do |param|
      declare(param)
      define(param)
    end
    puts stmt.function.body
    resolve(stmt.function.body)
    end_scope
    
    @current_function = enclosing_function
  end


  def resolve_local(expr, name)
    @scopes.reverse.each_with_index do |scope, i|
      if scope.key?(name.lexeme)
        @interpreter.resolve(expr, i)
        return
      end
    end
  end

  def begin_scope
    @scopes.push Hash.new
  end

  def end_scope
    @scopes.pop
  end

  def declare(name)
    return if @scopes.empty?

    scope = @scopes.last
    if scope.key?(name.lexeme)
      Lox.error(name, 'Variable with this name already declared in this scope.')
    end
    scope[name.lexeme] = false
  end

  def define(name)
    return if @scopes.empty?

    @scopes.last[name.lexeme] = true
  end
end