require 'net/http'
require 'rubygems'
require 'rack'
require 'hpricot'
require 'delegate'

# 
# Net::HTTPHeader.class_eval do
#   # handle multiple parameters with the same name
#   def form_data=(params, sep = '&')
#     self.body = params.map {|k,vs|
#       if vs.is_a?(Array)
#         vs.map{|v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }
#       else
#         "#{urlencode(k.to_s)}=#{urlencode(vs.to_s)}"
#       end
#     }.join(sep)
#     self.content_type = 'application/x-www-form-urlencoded'
#   end
# end

class RatHole
  def initialize(ip)
    @ip = ip
  end
  
  def call(env)
    Net::HTTP.start(@ip) do |http|
      # http.instance_eval{@socket = SocketSpy.new(@socket)}

      source_headers = {}
      # env.select{|k,v| k =~ /^HTTP/}.each do |k, v|
      #   next if k =~ /^rack/i
      #   key = k.split(/_/)[1..-1].collect{|e| e.capitalize}.join('-')
      #   source_headers[key] = v
      # end

      response = http.get(env['REQUEST_URI'], source_headers)
      code = response.code.to_i
      headers = camel_case_keys(response.to_hash)
      body = response.body

      [code, headers, body]
    end
  end
  
  def camel_case_keys(headers)
    tmp = {}
    headers.each{|k,v|
      tmp[k.gsub(/(^.|-.)/) { $1.upcase }] = v
    }
    tmp
  end
end
