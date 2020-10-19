require_relative 'lib'

class LoxFunction < LoxCallable
  def initialize(name, declaration, closure)
    @name = name
    @declaration = declaration
    @closure = closure
  end

  def call(interpreter, arguments)
    environment = Environment.new(@closure)
    @declaration.parameters.each_with_index do |param, i|
      environment.define(param.lexeme, arguments[i])
    end

    begin
      interpreter.execute_block(@declaration.body, environment)
    rescue Return => res
      return res.value
    end
    nil
  end

  def arity
    @declaration.parameters.size
  end

  def to_s
    return "<fn>" if @name.nil?
    "<fn #{@name}>"
  end
end
