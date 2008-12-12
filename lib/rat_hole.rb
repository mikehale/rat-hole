require 'net/http'
require 'rubygems'
require 'rack'
require 'hpricot'
require 'delegate'

class SocketSpy < SimpleDelegator
  def write(content)
    p :writing => content
    # __getobj__.write content
  end
end
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
      response = http.get('/request', {})
    end
    
    [0, {}, '']
  end
end
