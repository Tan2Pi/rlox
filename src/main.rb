require_relative 'lox'

if ARGV.length > 1
    puts 'Usage: rlox [script]'
    exit 64
elsif ARGV.length == 1
    Lox.run_file(ARGV[0])
else
    Lox.run_prompt
end