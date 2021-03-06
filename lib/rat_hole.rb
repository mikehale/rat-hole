require 'net/http'
require 'rack'
require 'delegate'
require 'util'
require 'open3'

class RatHole

  def initialize(host, tidy=false)
    @host = host
    @tidy = tidy
  end

  def process_user_request(rack_request)
    rack_request
  end

  def process_server_response(rack_response, rack_request)
    rack_response
  end

  def call(env)
    Net::HTTP.start(@host) do |http|
      http.instance_eval{@socket = MethodSpy.new(@socket){|method| method =~ /#{ENV['RH_METHOD_SPY_FILTER']}/}} if $DEBUG
      env.delete('HTTP_ACCEPT_ENCODING')
      source_request = Rack::Request.new(env)
      process_user_request(source_request)
      source_headers = request_headers(source_request.env)
      
      if source_request.query_string.nil? || source_request.query_string == ''
        request_uri = source_request.path_info
      else
        request_uri = "#{source_request.path_info}?#{source_request.query_string}"
      end

      if source_request.get?
        response = http.get(request_uri, source_headers)
      elsif source_request.post?
        post = Net::HTTP::Post.new(request_uri, source_headers)
        post.form_data = source_request.POST
        response = http.request(post)
      end

      code = response.code.to_i
      headers = response.to_hash
      body = response.body || ''
      headers.delete('Transfer-Encoding')

      server_response = Rack::Response.new(body, code, headers)
      whack_array(server_response)
      tidy_html(body) if server_response["Content-Type"] =~ /text\/html/ && @tidy
      
      process_server_response(server_response, source_request)
      server_response.finish
    end
  end

  def whack_array(server_response)
    server_response.headers.each do |k, v|
      if v.is_a?(Array) && v.size == 1
        server_response[k] = v.first
      end
    end
  end

  def tidy_html(body)
    if `which tidy` == ''
      $stderr.puts "tidy not found in path"
      return
    end
    tidied, errors = Open3.popen3('tidy -ascii') do |stdin, stdout, stderr|
      stdin.print body
      stdin.close
      [stdout.read, stderr.read]
    end
    $stderr.puts errors if $DEBUG
    body.replace(tidied) if tidied != ""
  end

  def request_headers(env)
    env.select{|k,v| k =~ /^HTTP/}.inject({}) do |h, e|
      k,v = e
      h.merge(k.split('_')[1..-1].join('-').to_camel_case => v)
    end
  end
end

# This class simply extends RatHole and does nothing.
# It's only useful for making sure that you have everything hooked up correctly.
class EmptyRatHole < RatHole
end