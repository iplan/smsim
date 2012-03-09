module Smsim
  module Errors
    class Error < StandardError

      attr_reader :code

      def initialize(code, message)
        @code = code
        super(message)
      end

    end
  end
end
