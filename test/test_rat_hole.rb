$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rr'
require 'delegate'
require 'test/unit'
require 'rat_hole'
require 'rat_hole_test'
require 'mock_request'
require 'hpricot'
require 'ruby-debug'

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

  def proxied_request
    MockRequest.new(@io.written)
  end

  def send_get_request(rack_env={}, uri='/someuri')
    opts = {:lint=>true}.merge(rack_env)
    rh = RatHole.new('127.0.0.1')
    Rack::MockRequest.new(rh).get(uri, opts)
  end

  def send_post_request(body='', uri='/someuri')
    rh = RatHole.new('127.0.0.1')
    Rack::MockRequest.new(rh).post(uri, {:lint=>true, :input=> body})
  end

  def test_response_unchanged
    expected_body = 'the body'
    mock_server(:body => expected_body)
    response = send_get_request

    assert_equal 200, response.status
    assert_equal expected_body, response.body
  end

  def test_headers_normalized
    mock_server(:headers => {'server' => 'freedom-2.0', 'set-cookie' => 'ronpaul=true'})
    response = send_get_request
    assert_equal('ronpaul=true', response.headers['Set-Cookie'])
    assert_equal('freedom-2.0', response.headers['Server'])
  end

  def test_default_body
    mock_server(:body => nil)
    response = send_get_request
    assert_equal '', response.body
  end

  def test_get_request
    mock_server
    send_get_request
    assert proxied_request.get?
  end

  def test_post_request
    mock_server
    send_post_request("field1=value1")
    assert proxied_request.post?
    assert proxied_request.body.include?("field1=value1")
  end

  def test_post_duplicate_keys
    mock_server
    send_post_request("field1=value1&field1=value2")
    assert_equal("field1=value1&field1=value2", proxied_request.body)
  end

  def test_post_data_urlencoded
    mock_server
    send_post_request("field%201=value%201")
    assert("field%201=value%201", proxied_request.body)
  end

  def test_convert_rack_env_to_http_headers
    headers_added_by_rack = {"Accept"=>"*/*", "Host"=>"127.0.0.1"}
    expected_headers = {"X-Forwarded-Host"=>"www.example.com"}.merge(headers_added_by_rack)

    mock_server
    send_get_request({"HTTP_X_FORWARDED_HOST"=>"www.example.com", "NON_HTTP_HEADER" => '42'})
    assert_equal(expected_headers, proxied_request.headers)
  end

  def test_content_type
    mock_server(:headers=>{'content-type' => ['image/gif']})
    response = send_get_request
    assert_equal 'image/gif', response.headers['Content-Type']

    mock_server
    response = send_get_request
    assert_equal 'text/html', response.headers['Content-Type']
  end

  def test_convert_rack_env_to_http_headers_more_data
    expected_headers = {
      "X-Forwarded-Host"=>"www.example.com",
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
      "HTTP_X_FORWARDED_HOST"=>"www.example.com",
      "HTTP_ACCEPT_ENCODING"=>"gzip,deflate",
      "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
      "HTTP_CACHE_CONTROL"=>"max-age=0",
      "HTTP_IF_NONE_MATCH"=>"\"58dc30c-216-3d878fe2\"-gzip",
      "HTTP_ACCEPT_LANGUAGE"=>"en-us,en;q=0.5",
      "HTTP_HOST"=>"localhost:4001",
      "HTTP_REFERER"=>"http://www.example.com/posts/",
      "HTTP_COOKIE"=>"cookie1=YWJj; cookie2=ZGVm",
      "HTTP_ACCEPT_CHARSET"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
      "HTTP_X_FORWARDED_SERVER"=>"www.example.com",
      "HTTP_IF_MODIFIED_SINCE"=>"Tue, 17 Sep 2002 20:26:10 GMT",
      "HTTP_X_FORWARDED_FOR"=>"127.0.0.1",
      "HTTP_ACCEPT"=>"image/png,image/*;q=0.8,*/*;q=0.5",
      "HTTP_CONNECTION"=>"Keep-Alive",}

    mock_server(:body => 'not testing this')
    send_get_request(rack_env)
    assert_equal(expected_headers, proxied_request.headers)
  end

  def test_request_uri
    mock_server
    send_get_request({}, '/uri?with=param')
    assert_equal('/uri?with=param', proxied_request.uri)

    mock_server
    send_get_request({}, '/uri')
    assert_equal('/uri', proxied_request.uri)

    mock_server
    send_post_request('', '/uri?with=param')
    assert_equal('/uri?with=param', proxied_request.uri)
  end
end

class TestEmptyRatHole < RatHoleTest
  def test_has_proper_response
    through_the(EmptyRatHole, 'halethegeek.com') do |raw_response, app_response|
      assert_not_equal 0, raw_response.headers
      assert_equal raw_response.status.to_i, app_response.status.to_i
      assert_equal raw_response.headers, app_response.headers
      assert_equal raw_response.body.to_s, app_response.body.to_s
    end
  end
end

class PoliticalAgendaRatHoleTest < RatHoleTest
  def test_has_proper_response
    through_the(PoliticalAgendaRatHole, 'terralien.com') do |raw_response, app_response|
      assert_equal raw_response.status.to_i, app_response.status.to_i
      assert !raw_response.headers.has_key?('Ron-Paul')
      assert app_response.headers.has_key?('Ron-Paul')

      assert !raw_response.body.to_s.include?('http://ronpaul.com')
      assert app_response.body.to_s.include?('http://ronpaul.com')
    end
  end
end

class PoliticalAgendaRatHole < RatHole
  def process_server_response(rack_response, rack_request)
    if(rack_response.content_type == 'text/html')
      doc = Hpricot(rack_response.body.first)
      (doc/"a").set('href', 'http://ronpaul.com')
      rack_response.body.first.replace(doc.to_html)
      rack_response.headers['Ron-Paul'] = 'wish I could have voted for this guy'
    end
  end
end
