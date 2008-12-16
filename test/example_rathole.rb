require 'rat_hole'
=begin

  USER Request  --->
      ---  RatHoleProxy.process_user_request(headers, body) --->
                                                                <==========> OLD SCHOOL SERVER
      <---  RatHoleProxy.process_server_response(headers, body) ---
  User Response  <---
=end
class MyRatHole < RatHole
  def process_user_request(headers, body)
    
  end

  def process_server_response(headers, body)
  end




  
end
