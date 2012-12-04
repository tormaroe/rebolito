
$assertions = []
$errors = []

def example txt, &block
  if block.call
    $assertions << true
    print '.'
  else
    $assertions << false
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
  if $assertions.all? { |a| a }
    puts " #{$assertions.size} assertions, all ok!"
  else
    puts " *** #{$assertions.size} assertions, #{$assertions.count { |a| not a }} FAILED!"
  end
  if $errors.size > 0
    puts " *** #{$errors.size} EXCEPTIONS!"
    $errors.each {|e| puts e}
  end
end

print "Executing program specification:"
