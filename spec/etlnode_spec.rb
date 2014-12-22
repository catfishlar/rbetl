require 'rspec'

describe 'Basic ETLNode' do

  it 'should echo a file' do
    input = double("input", get: ["hi","hello"])
    bob = input.get
    bob.should == ["bob"]
  end
end