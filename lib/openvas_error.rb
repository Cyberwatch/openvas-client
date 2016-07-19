module OpenVASClient
  # Handle errors return by OpenVAS API in XML
  class OpenVASError < StandardError
    attr_reader :status

    def initialize(status)
      super
      @status = status
    end
  end
end
