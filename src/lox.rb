require_relative 'lib'

class Lox

  class << self
    @@had_error = false
    @@had_runtime_error = false
    
    @@interpreter = Interpreter.new

    def run_file(path)
      run(IO.read(path))
      exit 65 if @@had_error
      exit 70 if @@had_runtime_error
    end

    def run_prompt
      loop do
        print 'rlox > '
        run(gets.chomp)
        @@had_error = false
      end
    end

    def run(source)
      exit 0 if source == 'exit'
      scanner = Scanner.new(source)
      tokens = scanner.scan_tokens()
      parser = Parser.new(tokens)
      statements = parser.parse()

      return if @@had_error

      resolver = Resolver.new(@@interpreter)
      resolver.resolve_all(statements)

      return if @@had_error

      @@interpreter.interpret(statements)
    end

    def runtime_error(error)
      puts "#{error.message}\n[line #{error.token.line}]"
      @@had_runtime_error = true
    end

    def error(line_or_token, message)
      if line_or_token.is_a?(Numeric)
        report(line_or_token, '', message)
      elsif line_or_token.is_a?(Token)
        error_with_token(line_or_token, message)
      end
    end

    def error_with_token(token, message)
      if token.type == :eof
        report(token.line, ' at end', message)
      else
        report(token.line, " at '#{token.lexeme}'", message)
      end
    end

    private
    
    def report(line, where, message)
      puts "[line #{line}] Error #{where}: #{message}"
      @@had_error = true
    end
  end
end
