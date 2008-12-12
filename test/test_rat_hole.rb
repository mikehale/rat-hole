require 'rubygems'
require 'rr'
require 'ruby-debug'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'test/unit'
require 'rat_hole'


require 'rubygems'
require 'rack'

class StubServer
  attr_writer :body
  def call(env)
    [200, {"Content-Type" => "text/html"}, @body]
  end
end

old_school_server = StubServer.new
old_school_server.body = "bird is the old word"

foo = Rack::Handler::Mongrel.run old_school_server, :Port => 9292
foo.close
p "non blocking call"

old_school_server.body = "<h3>bird is the word</h3>"

class TestRatHole < Test::Unit::TestCase
  include RR::Adapters::TestUnit
  
  def test_passes_unmodified_response
    expected_body = "some string"
    actual_response = Net::HTTPResponse.new('1.1', '200', "OK")
    Net::HTTPResponse.class_eval do
      @body = expected_body
    end
    
    Net::HTTP.class_eval do
      def connect; end
    end
    source_headers = {}
    # mock(Net::HTTP).connect
    mock(Net::HTTP).get('/request', source_headers) { actual_response }
    rh = RatHole.new('127.0.0.1')
    
    env = {}
    result = rh.call(env)

    expected_headers = {}
    assert_equal 200, result[0]
    assert_equal expected_headers, result[1]
    assert_equal expected_body, result[2]
    
    # create rathole
    # request from new site url
    # assert response is the same as the old school url response
    # spoof response
    # assert response is unchanged
  end
end