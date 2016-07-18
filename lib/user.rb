module OpenVASClient
  class User
    attr_reader :id

    # Name can't contain spaces
    def initialize(name, password, agent)
      @agent = agent
      @name = name
      @password = password
      user_xml = Nokogiri::XML::Builder.new do |xml|
        xml.create_user{
          xml.name @name
          xml.password @password
        }
      end
      result = Nokogiri::XML(@agent.sendrecv(user_xml.to_xml))
      unless result.at_css('create_user_response')[:status].eql?('201')
        raise OpenVASError.new(result.at_css('create_user_response')[:status]), result.at_css('create_user_response')[:status_text]
      end
      @id = result.at_css('create_user_response')[:id]
    end
  end
end
