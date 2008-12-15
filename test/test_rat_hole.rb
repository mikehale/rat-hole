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

def mock_server(opts={})
  host =  opts[:host] || '127.0.0.1'
  code =  opts[:code] || 200
  headers =  opts[:headers] || {}
  body =  opts[:body] || ''

  response = [%(HTTP/1.1 #{code} OK)]
  headers.each{|k,vs|
    response << if vs.is_a?(Array)
      vs.map{|v| "#{k.to_s}: #{v.to_s}" }
    else
      "#{k.to_s}: #{vs.to_s}"
    end
  }
  response << ''
  response << %(#{body})
  response = response.join("\r\n")

  io = StringIO.new(response)
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
    expected_headers = {'server' => ['apache']}
    mock_server(:body => expected_body, :headers => expected_headers)

    rh = RatHole.new('127.0.0.1')
    env = {'REQUEST_URI' => '/request'}
    result = rh.call(env)

    assert_equal 200, result[0]
    assert_equal expected_headers, result[1]
    assert_equal expected_body, result[2]
  end
end