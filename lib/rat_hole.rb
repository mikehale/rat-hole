require 'net/http'
require 'rubygems'
require 'rack'
require 'hpricot'
require 'delegate'
require 'util'

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

  def process_user_request(rack_request)
    rack_request
  end

  def process_server_response(rack_response)
    rack_response
  end

  def call(env)
    Net::HTTP.start(@ip) do |http|
      http.instance_eval{@socket = MethodSpy.new(@socket){|symbol|symbol.to_s =~ /write/}} if $DEBUG

      source_request = process_user_request(Rack::Request.new(env))
      source_headers = request_headers(source_request.env)

      if source_request.get?
        response = http.get(source_request.path_info, source_headers)
      elsif source_request.post?
        post = Net::HTTP::Post.new(source_request.path_info, source_headers)
        post.form_data = source_request.POST
        response = http.request(post)
      end

      code = response.code.to_i
      headers = response.to_hash
      body = response.body

      process_server_response(Rack::Response.new(body, code, headers)).finish
    end
  end

  def request_headers(env)
    env.select{|k,v| k =~ /^HTTP/}.inject({}) do |h, e|
      k,v = e
      h.merge(k.split('_')[1..-1].join('-').to_camel_case => v)
    end
  end
end
