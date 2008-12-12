require 'rubygems'
require 'rr'
require 'delegate'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'test/unit'
require 'rat_hole'

class SocketSpy < SimpleDelegator
  def write(content)
    p :writing => content
    __getobj__.write content
  end

  def readline
    content = __getobj__.readline
    p :reading => content
    content
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