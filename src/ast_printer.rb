require_relative 'expr'
require_relative 'token'
class AstPrinter
  def print(expr)
    return expr.accept(self)
  end

  def visit_binary_expr(expr)
    return parenthesize(expr.operator.lexeme, expr.left, expr.right)
  end

  def visit_grouping_expr(expr)
    return parenthesize('group', expr.expression)
  end

  def visit_literal_expr(expr)
    return "nil" if expr.value == nil
    return expr.value.to_s
  end

  def visit_unary_expr(expr)
    return parenthesize(expr.operator.lexeme, expr.right)
  end

  def parenthesize(name, *exprs)
    expression = '(' + name
    exprs.each do |expr|
      expression.concat(' ')
      expression.concat(expr.accept(self))
    end
    expression.concat(')')
    return expression
  end
end

# expression = Expr::Binary.new(
#   Expr::Unary.new(
#     Token.new(:minus, '-', nil, 1),
#     Expr::Literal.new(123)),
#   Token.new(:star, '*', nil, 1),
#   Expr::Grouping.new(Expr::Literal.new(45.67))
# )

# printer = AstPrinter.new
# puts printer.print(expression)