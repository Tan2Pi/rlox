
class Expr
  class Visitor
    def visit_assign_expr(expr);end
    def visit_binary_expr(expr);end
    def visit_call_expr(expr);end
    def visit_function_expr(expr);end
    def visit_get_expr(expr);end
    def visit_grouping_expr(expr);end
    def visit_literal_expr(expr);end
    def visit_logical_expr(expr);end
    def visit_set_expr(expr);end
    def visit_super_expr(expr);end
    def visit_this_expr(expr);end
    def visit_unary_expr(expr);end
    def visit_variable_expr(expr);end
  end
  @@names = {
            'Binary' => [:left, :operator, :right], 
            'Grouping' => [:expression], 
            'Literal' => [:value], 
            'Unary' => [:operator, :right],
            'Variable' => [:name],
            'Assign' => [:name, :value],
            'Logical' => [:left, :operator, :right],
            'Call' => [:callee, :paren, :arguments],
            'Function' => [:parameters, :body]
  }
  Assign = Struct.new(*@@names['Assign']) do
    def accept(visitor)
      visitor.visit_assign_expr(self)
    end
  end
  Binary = Struct.new(*@@names['Binary']) do
    def accept(visitor)
      visitor.visit_binary_expr(self)
    end
  end
  Call = Struct.new(*@@names['Call']) do
    def accept(visitor)
      visitor.visit_call_expr(self)
    end
  end
  Function = Struct.new(*@@names['Function']) do
    def accept(visitor)
      visitor.visit_function_expr(self)
    end
  end
  Grouping = Struct.new(*@@names['Grouping']) do
    def accept(visitor)
      visitor.visit_grouping_expr(self)
    end
  end
  Literal = Struct.new(*@@names['Literal']) do
    def accept(visitor)
      visitor.visit_literal_expr(self)
    end
  end
  Logical = Struct.new(*@@names['Logical']) do
    def accept(visitor)
      visitor.visit_logical_expr(self)
    end
  end
  Unary = Struct.new(*@@names['Unary']) do
    def accept(visitor)
      visitor.visit_unary_expr(self)
    end
  end
  Variable = Struct.new(*@@names['Variable']) do
    def accept(visitor)
      visitor.visit_variable_expr(self)
    end
  end
end