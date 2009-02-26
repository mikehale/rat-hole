require 'test/unit'

class RatHoleTest < Test::Unit::TestCase
  def through_the(rathole_klass, host)
    app = Rack::Builder.new do
      use Rack::ShowExceptions
      use Rack::ShowStatus
      run rathole_klass.new(host)
    end

    app_response = Rack::MockRequest.new(app).get('/', {})
    raw_response = Net::HTTP.start(host) do |http|
      http.get('/', {})
    end
    # Wrap raw_response in Rack::Response to make things easier to work with.
    raw_response = Rack::Response.new(raw_response.body, raw_response.code, raw_response.to_hash)
    normalize_headers(raw_response.headers)
    normalize_headers(app_response.headers)

    yield(raw_response, app_response)
  end

  def normalize_headers(headers)
    new_headers = headers.inject({}){|h,e|
      k,v = e
      # remove headers that change or that we remove
      unless k =~ /cookie|transfer|date|runtime|last-modified/i
        v = [v] unless v.is_a? Array #normalize things
        h.merge!(k => v)
      end
      h
    }
    headers.replace(new_headers)
  end

  def test_nothing
  end
end