require_relative 'lib'

class Return < RuntimeError
  attr_reader :value

  def initialize(value)
    @value = value
  end
end