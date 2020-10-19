require_relative 'runtime_error'
class Environment
  attr_accessor :values
  attr_accessor :enclosing

  def initialize(enclosing = nil)
    @enclosing = enclosing
    @values = {}
  end

  def define(name, value)
    @values[name] = value
  end

  def ancestor(distance)
    environment = self
    (0..distance).each do |i|
      environment = environment.enclosing
    end

    environment
  end

  def get_at(distance, name)
    ancestor(distance).values[name]
  end

  def assign_at(distance, name, value)
    ancestor(distance).values[name.lexeme] = value
  end
  
  def get(name)
    return @values[name.lexeme] if @values.key?(name.lexeme)
    
    return @enclosing.get(name) unless @enclosing.nil?
    raise LoxRuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
  end

  def assign(name, value)
    if @values.key?(name.lexeme)
      @values[name.lexeme] = value
      return
    end
    if !@enclosing.nil?
      @enclosing.assign(name, value)
      return
    end

    raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
  end

end