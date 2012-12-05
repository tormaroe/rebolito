
$assertions = []
$errors = []

class TestInfo
  attr_reader :ok, :name
  def initialize name, ok
    @ok = ok ; @name = name
  end
end

def example txt, &block
  if block.call
    $assertions << TestInfo.new(txt, true)
    print '.'
  else
    $assertions << TestInfo.new(txt, false)
    print 'f'
  end
end

def explanation txt, &block
  begin
    block.call
  rescue Exception => e
    $errors << e
    print 'e'
  end
end

def the_end!
  puts; puts
  if $assertions.all? { |a| a.ok }
    puts " #{$assertions.size} assertions, all ok!"
  else
    $assertions.select{|a| not a.ok }.each {|a| puts "FAILED: #{a.name}" }
    puts " *** #{$assertions.size} assertions, #{$assertions.count { |a| not a.ok }} FAILED!"
  end
  if $errors.size > 0
    puts " *** #{$errors.size} EXCEPTIONS!"
    $errors.each {|e| puts e}
  end
end

puts "Executing program specification:"
