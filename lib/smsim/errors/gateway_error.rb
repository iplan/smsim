module Smsim
  module Errors
    class GatewayError < Error
      # error codes legend
      # 100 - Response xml is invalid
      # -1 - Failed
      # -2 - BadUserNameOrPassword=-2
    end
  end
end
