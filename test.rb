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

class MyStringIO < StringIO
  def write(content)
    0
  end
end

class TestRatHole < Test::Unit::TestCase
  def test_it
    io = MyStringIO.new(%(HTTP/1.1 200 OK\r\n))
    mock(TCPSocket).open('127.0.0.1', 80) { io }

    Net::HTTP.start('127.0.0.1') do |http|
      http.instance_eval{@socket = SocketSpy.new(@socket)}
      p http.get('/', {})
    end
  end
end