class SocketSpy < SimpleDelegator
  def write(content)
    p :writing => content
    __getobj__.write content
  end

  [:readline, :readuntil, :read_all, :read].each{|symbol|
    define_method(symbol) do |*args|
      content = __getobj__.send(symbol, *args)
      p :reading => content
      content
    end
  }
end

class MethodSpy
  def initialize(delegate, &block)
    @delegate = delegate
    @filter = block
  end

  def method_missing(symbol, *args, &block)
    result = @delegate.send(symbol, *args, &block)
    @block.call if @block
    p [symbol, args, result, block] if @filter && @filter.call(symbol.to_s)
    result
  end
end

class String
  def to_camel_case(split_on='-')
    self.split(split_on).collect{|e| e.capitalize}.join(split_on)
  end
end