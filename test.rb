require 'rubygems'
require 'test/unit'
require 'rr'
require 'delegate'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

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

def mock_server(host, port, code, body)
  io = StringIO.new(%(HTTP/1.1 #{code} OK\r\n\r\n#{body}))
  class << io
    def write(content)
      0
    end
  end
  
  mock(TCPSocket).open(host, port) { io }
end


class TestRatHole < Test::Unit::TestCase
  def test_it
    mock_server('127.0.0.1', 80, 200, 'the body')

    Net::HTTP.start('127.0.0.1') do |http|
      # http.instance_eval{@socket = SocketSpy.new(@socket)}
      response = http.get('/', {})
      assert_equal 'the body', response.body
    end
  end
end