require 'test/unit'

class RatHoleTest < Test::Unit::TestCase
  def through_the(rathole_klass, host, uri='/', headers={})
    app = Rack::Builder.new do
      use Rack::ShowExceptions
      use Rack::ShowStatus
      run rathole_klass.new(host)
    end

    app_response = Rack::MockRequest.new(app).get(uri, headers)
    raw_response = Net::HTTP.start(host) do |http|
      http.get(uri, headers)
    end
    # Wrap raw_response in Rack::Response to make things easier to work with.
    raw_headers = raw_response.to_hash
    raw_response = Rack::Response.new(raw_response.body, raw_response.code, raw_headers)
    normalize_headers(raw_response.headers)
    normalize_headers(app_response.headers)
    yield(raw_response, app_response)
  end

  def normalize_headers(headers)
    new_headers = headers.inject({}){|h,e|
      k,v = e
      # the value of these headers changes
      v = nil if k =~ /cookie|date|runtime|last-modified/i
      # skip headers that rat-hole removes
      unless k =~ /transfer/i
        v = v.first if v.is_a?(Array) && v.size == 1 #normalize things
        h.merge!(k => v)
      end
      h
    }
    headers.replace(new_headers)
  end

  def test_nothing #make autotest happy
  end
end