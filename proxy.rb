require 'net/http'
require 'rubygems'
require 'rack'
require 'hpricot'
require 'delegate'

class SocketSpy < SimpleDelegator
  def write(content)
    p :writing => content
    __getobj__.write content
  end
end

Net::HTTPHeader.class_eval do
  # handle multiple parameters with the same name
  def form_data=(params, sep = '&')
    self.body = params.map {|k,vs|
      if vs.is_a?(Array)
        vs.map{|v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }
      else
        "#{urlencode(k.to_s)}=#{urlencode(vs.to_s)}"
      end
    }.join(sep)
    self.content_type = 'application/x-www-form-urlencoded'
  end
end

class RatHole
  def call(env)
    Net::HTTP.start('some.ip') do |http|
      http.instance_eval{@socket = SocketSpy.new(@socket)} if $DEUBG
      source_request = Rack::Request.new(env)
      source_headers = {}
      env.select{|k,v| k =~ /^HTTP/}.each do |k, v|
        next if k =~ /^rack/i
        key = k.split(/_/)[1..-1].collect{|e| e.capitalize}.join('-')
        source_headers[key] = v
      end
      source_headers['Host'] = 'www.example.com'

      response = if source_request.get?
        http.get(env['REQUEST_URI'], source_headers)
      elsif source_request.post?
        post = Net::HTTP::Post.new(env['REQUEST_URI'], source_headers)
        post.form_data = source_request.POST
        http.request(post)
      end

      headers = response.to_hash
      headers.delete('transfer-encoding')
      if set_cookie = (headers['set-cookie'] || headers['Set-Cookie'])
        headers['Set-Cookie'] = set_cookie
        headers.delete('set-cookie')
      end
      body = response.body || ''

      if(response.content_type == 'text/html')
        host = env['HTTP_X_FORWARDED_HOST'] || env['HTTP_HOST']
        fix_forums(body, env)
        fix_rss(body, host)
      end

      [response.code.to_i, headers, body]
    end
  end

  def fix_rss(body, host)
    body.gsub!('www.example.com/blog2/', "#{host}/blog2/")
  end

  def fix_forums(body, env)
    body.gsub!(/<option(.*)\/>(.*)$/i, '<option\1>\2</option>')
    body.gsub!(/<select(.*)\/>/i, '<select\1>')

    if body =~ /meta http-equiv=.?refresh.*<!doctype/im
      body.gsub!(/.*(<!doctype.*)/im, '\1')
      doc = Hpricot(body)

      head = doc.at("head")
      head.inner_html = %(#{head.inner_html}\n<meta http-equiv="refresh" content="1; url=/dc/dcboard.php"/>)

      body.replace(doc.to_html)
    end
  end
end

run RatHole.new
