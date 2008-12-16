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
  def initialize(delegate, &block)
    @delegate = delegate
    @filter = block
  end

  def method_missing(symbol, *args, &block)
    result = @delegate.send(symbol, *args, &block)
    @block.call if @block
    p [symbol, args, result, block] if @filter && @filter.call(symbol)
    result
  end

end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

class TestRatHole < Test::Unit::TestCase
  def mock_server(opts={})
    opts[:host] = opts[:host] || '127.0.0.1'
    opts[:code] = opts[:code] || 200
    opts[:headers] = opts[:headers] || {}

    host = opts[:host]
    code = opts[:code]
    headers = opts[:headers]
    body = opts[:body]

    response = [%(HTTP/1.1 #{code} OK)]
    headers.each{|k,vs|
      if vs.is_a?(Array)
        response << vs.map{|v| "#{k.to_s}: #{v.to_s}" }
      else
        response << "#{k.to_s}: #{vs.to_s}"
      end
    }
    response << ''
    response << %(#{body})
    response = response.join("\r\n")

    @io = StringIO.new(response)
    class << @io
      attr_reader :written

      def write(content)
        @written = '' unless @written
        @written << content
        0
      end
    end

    mock(TCPSocket).open(host, 80) { @io }
  end

  def request_line
    @io.written.split("\r\n").first
  end

  def request_body
    @io.written.split("\r\n\r\n")[1]
  end

  def forwarded_headers
    #TODO: might not work with posting
    @io.written.split("\r\n")[1..-1].inject({}){|h,e|
      k,v = e.split(': ')
      h.merge k => v
    }
  end

  def send_get_request(rack_env={})
    env = {"REQUEST_URI"=>"/remote/path/img.gif", "REQUEST_METHOD" => 'GET'}.merge(rack_env)
    rh = RatHole.new('127.0.0.1')
    rh.call(env)
  end

  def send_post_request(rack_env={}, body='')
    env = {"REQUEST_URI"=>"/remote/path/img.gif", "REQUEST_METHOD" => 'POST', 'rack.input' => StringIO.new(body)}.merge(rack_env)
    rh = RatHole.new('127.0.0.1')
    rh.call(env)
  end

  def test_response_unchanged
    expected_body = 'the body'
    mock_server(:body => expected_body)
    result = send_get_request

    assert_equal 200, result[0]
    assert_equal expected_body, result[2]
  end

  def test_headers_camelcased
    mock_server(:headers => {'server' => 'freedom-2.0', 'set-cookie' => 'ronpaul=true'})
    result = send_get_request
    assert_equal({'Set-Cookie' => ['ronpaul=true'], 'Server' => ['freedom-2.0']}, result[1])
  end

  def test_default_body
    mock_server(:body => nil)
    result = send_get_request
    assert_equal '', result[2]
  end

  def test_convert_rack_env_to_http_headers
    mock_server
    send_get_request({"HTTP_X_FORWARDED_HOST"=>"www.example.com"})
    assert(forwarded_headers.has_key?('X-Forwarded-Host'))
  end

  def test_get_request
    mock_server
    send_get_request
    assert_equal 'GET', request_line.split(' ').first
  end

  def test_post_request
    mock_server
    send_post_request({}, "field1=value1")
    assert_equal 'POST', request_line.split(' ').first
    assert request_body.include?("field1=value1")
  end

  def test_post_duplicate_keys
    mock_server
    send_post_request({}, "field1=value1&field1=value2")
    assert_equal("field1=value1&field1=value2", request_body)
  end

  def test_post_data_urlencoded
    mock_server
    send_post_request({}, "field%201=value%201")
    assert("field%201=value%201", request_body)
  end

  def test_convert_rack_env_to_http_headers_more_data
    expected_headers = {
      "X-Forwarded-Host"=>"www.example.com",
      "Accept-Encoding"=>"gzip,deflate",
      "User-Agent"=>"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
      "Cache-Control"=>"max-age=0",
      "If-None-Match"=>"\"58dc30c-216-3d878fe2\"-gzip",
      "Accept-Language"=>"en-us,en;q=0.5",
      "Host"=>"localhost:4001",
      "Referer"=>"http://www.example.com/posts/",
      "Cookie"=>"cookie1=YWJj; cookie2=ZGVm",
      "Accept-Charset"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
      "X-Forwarded-Server"=>"www.example.com",
      "If-Modified-Since"=>"Tue, 17 Sep 2002 20:26:10 GMT",
      "X-Forwarded-For"=>"127.0.0.1",
      "Accept"=>"image/png,image/*;q=0.8,*/*;q=0.5",
      "Connection"=>"Keep-Alive"}

    rack_env = {"SERVER_NAME"=>"localhost",
      "rack.url_scheme"=>"http",
      "rack.run_once"=>false,
      "rack.input"=>'',
      "CONTENT_LENGTH"=>nil,
      "HTTP_X_FORWARDED_HOST"=>"www.example.com",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
      "PATH_INFO"=>"/remote/path/img.gif",
      "SCRIPT_NAME"=>"",
      "rack.errors"=>'',
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_IF_NONE_MATCH"=>"\"58dc30c-216-3d878fe2\"-gzip",
      "HTTP_ACCEPT_LANGUAGE"=>"en-us,en;q=0.5",
      "HTTP_HOST"=>"localhost:4001",
      "SERVER_ADDR"=>"127.0.0.1",
      "SERVER_PROTOCOL"=>"HTTP/1.1",
      "REMOTE_ADDR"=>"127.0.0.1",
      "SERVER_SOFTWARE"=>"Apache/2.2.9 (Unix) mod_ssl/2.2.9 OpenSSL/0.9.7l DAV/2 proxy_html/3.0.1 Phusion_Passenger/2.0.4",
      "HTTP_REFERER"=>"http://www.example.com/posts/",
      "rack.multithread"=>false,
      "rack.version"=>[0, 1],
      "HTTP_COOKIE"=>"cookie1=YWJj; cookie2=ZGVm",
      "HTTP_ACCEPT_CHARSET"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
      "rack.multiprocess"=>true,
      "HTTP_X_FORWARDED_SERVER"=>"www.example.com",
      "DOCUMENT_ROOT"=>"/var/www/apps/site/current/public",
      "REQUEST_URI"=>"/remote/path/img.gif",
      "SERVER_PORT"=>"4001",
      "HTTP_IF_MODIFIED_SINCE"=>"Tue, 17 Sep 2002 20:26:10 GMT",
      "QUERY_STRING"=>"",
      "REMOTE_PORT"=>"59282",
      "SERVER_ADMIN"=>"you@example.com",
      "_"=>"_",
      "HTTP_X_FORWARDED_FOR"=>"127.0.0.1",
      "HTTP_ACCEPT"=>"image/png,image/*;q=0.8,*/*;q=0.5",
      "HTTP_CONNECTION"=>"Keep-Alive",
      "REQUEST_METHOD"=>"GET"}

    mock_server(:body => 'not testing this')
    send_get_request(rack_env)
    assert_equal(expected_headers, forwarded_headers)
  end
end
