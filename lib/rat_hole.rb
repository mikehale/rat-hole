require 'net/http'
require 'rubygems'
require 'rack'
require 'hpricot'
require 'delegate'


Net::HTTPHeader.class_eval do
  # handle multiple parameters with the same name
  def form_data=(params, sep = '&')
    self.body = params.map {|key,value|
      if value.is_a?(Array)
        value.map{|v| param_line(key, v) }
      else
        param_line(key, value)
      end
    }.join(sep)
  end

  def param_line(k, v)
    "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}"
  end
end

class String
  def to_camel_case(split_on='-')
    self.split(split_on).collect{|e| e.capitalize}.join(split_on)
  end
end

class RatHole
  def initialize(ip)
    @ip = ip
  end

  def call(env)
    Net::HTTP.start(@ip) do |http|
      # http.instance_eval{@socket = MethodSpy.new(@socket){|symbol|symbol.to_s =~ /write/}}
      source_request = Rack::Request.new(env)
      source_headers = request_headers(env)

      if source_request.get?
        response = http.get(env['REQUEST_URI'], source_headers)
      elsif source_request.post?
        post = Net::HTTP::Post.new(env['REQUEST_URI'], source_headers)
        post.form_data = source_request.POST
        response = http.request(post)
      end

      code = response.code.to_i
      headers = camel_case_keys(response.to_hash)
      body = response.body

      [code, headers, body]
    end
  end

  def request_headers(env)
    env.select{|k,v| k =~ /^HTTP/}.inject({}) do |h, e|
      k,v = e
      h.merge(k.split('_')[1..-1].join('-').to_camel_case => v)
    end
  end

  def camel_case_keys(headers)
    headers.inject({}){|h,e|
      k,v=e
      h.merge(k.to_camel_case => v)
    }
  end
end
