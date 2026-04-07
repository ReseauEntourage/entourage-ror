RSpec::Matchers.define :be_boolean do
  match do |actual|
    actual == true || actual == false
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be a Boolean (true or false)"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be a Boolean"
  end
end
