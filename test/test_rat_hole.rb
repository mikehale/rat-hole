$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'rr'
require 'delegate'
require 'test/unit'
require 'ruby-debug'
require 'rat_hole'

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
  def initialize(delegate)
    @delegate = delegate
  end
  
  def method_missing(symbol, *args, &block)
    result = @delegate.send(symbol, *args, &block)
    p [symbol, args, result, block]
    result
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

def mock_server(host, code, body)
  io = StringIO.new(%(HTTP/1.1 #{code} OK\r\n\r\n#{body}))
  class << io
    def write(content)
      0
    end
  end

  mock(TCPSocket).open(host, 80) { io }
end

class TestRatHole < Test::Unit::TestCase
  def test_response_unchanged
    expected_body = 'the body'
    mock_server('127.0.0.1', 200, expected_body)

    rh = RatHole.new('127.0.0.1')
    env = {}
    result = rh.call(env)

    expected_headers = {}
    assert_equal 200, result[0]
    assert_equal expected_headers, result[1]
    assert_equal expected_body, result[2]
  end
end