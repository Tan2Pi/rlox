class Stmt
  class Visitor
    def visit_expression_statement(stmt);end
    def visit_print_statement(stmt);end
    def visit_var_statement(stmt);end
    def visit_block_statement(stmt);end
    def visit_if_statement(stmt);end
    def visit_while_statement(stmt);end
    def visit_break_statement(stmt);end
    def visit_class_statement(stmt);end
    def visit_function_statement(stmt);end
    def visit_return_statement(stmt);end
  end
  @@names = {
            'Expression' => [:expression], 
            'Print' => [:expression],
            'Var' => [:name, :initializer],
            'Block' => [:statements],
            'If' => [:condition, :then_branch, :else_branch],
            'While' => [:condition, :body],
            'Break' => [:break],
            'Function' => [:name, :function],
            'Return' => [:keyword, :value]
  }
  Block = Struct.new(*@@names['Block']) do
    def accept(visitor)
      visitor.visit_block_statement(self)
    end
  end
  Break = Struct.new(*@@names['Break']) do
    def accept(visitor)
      visitor.visit_break_statement(self)
    end
  end
  Expression = Struct.new(*@@names['Expression']) do
    def accept(visitor)
      visitor.visit_expression_statement(self)
    end
  end
  Function = Struct.new(*@@names['Function']) do
    def accept(visitor)
      visitor.visit_function_statement(self)
    end
  end
  If = Struct.new(*@@names['If']) do
    def accept(visitor)
      visitor.visit_if_statement(self)
    end
  end
  Print = Struct.new(*@@names['Print']) do
    def accept(visitor)
      visitor.visit_print_statement(self)
    end
  end
  Return = Struct.new(*@@names['Return']) do
    def accept(visitor)
      visitor.visit_return_statement(self)
    end
  end
  Var = Struct.new(*@@names['Var']) do
    def accept(visitor)
      visitor.visit_var_statement(self)
    end
  end
  While = Struct.new(*@@names['While']) do
    def accept(visitor)
      visitor.visit_while_statement(self)
    end
  end
end