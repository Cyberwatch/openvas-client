require 'openvas_error'

module OpenVASClient
  class Target
    attr_accessor :id

    def initialize(name, host, agent)
      @name = name
      @host = host
      @agent = agent
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_target {
          xml.name @name
          xml.hosts @host
        }
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      unless result.at_css('create_target_response')[:status].eql?('201')
        raise OpenVASError.new(result.at_css('create_target_response')[:status]), result.at_css('create_target_response')[:status_text]
      end
      @id = result.at_css('create_target_response')[:id]
    end

    def destroy
      target = Nokogiri::XML::Builder.new do |xml|
        xml.delete_target(target_id: self.id)
      end
      result = Nokogiri::XML(@agent.sendrecv(target.to_xml))
      result.at_xpath('//delete_target_response/@status').text.eql?('200')
    end

    def refresh
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_targets(target_id: self.id)
      end
      Hash.from_xml(@agent.sendrecv(task.to_xml)).deep_symbolize_keys
    end

    def all
      targets = Nokogiri::XML(@agent.sendrecv('<get_targets/>'))
      Hash.from_xml(targets.to_xml).deep_symbolize_keys
    end
  end
end
