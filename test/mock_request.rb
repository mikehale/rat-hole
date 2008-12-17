class MockRequest

  attr_reader :headers, :body, :uri

  def initialize(request_string)
    lines = request_string.split("\r\n")

    # find blank line which seperates the headers from the body
    index_of_blank = nil
    lines.each_with_index{|e,i|
      index_of_blank = i if e == ""
    }

    @type, @uri = lines.first.split(/\s+/)
    if index_of_blank
      @headers = lines[1..index_of_blank]
      @body = lines[(index_of_blank + 1)..-1].first
    else
      @headers = lines[1..-1]
    end

    @headers = @headers.inject({}){|h,e|
      k,v = e.split(/:\s+/)
      h.merge k => v
    }
  end

  def get?
    @type == 'GET'
  end

  def post?
    @type == 'POST'
  end
end