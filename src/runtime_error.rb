class LoxRuntimeError < RuntimeError
  attr_reader :token
  
  def initialize(token, message)
    super(message)
    @token = token
  end
end