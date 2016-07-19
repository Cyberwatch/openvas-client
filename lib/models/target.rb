require 'openvas_error'

module OpenVASClient
  class Target
    attr_accessor :id, :name

    def initialize(name, hosts, agent)
      @name = name
      @hosts = hosts
      @agent = agent
      unless self.class.exist(name, agent)
        create
      else
        import
      end
    end

    def create
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_target {
          xml.name @name
          xml.hosts @hosts
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

    def import
      target = Nokogiri::XML::Builder.new do |xml|
        xml.get_targets(filter: "name=#{@name}")
      end
      result = Hash.from_xml(@agent.sendrecv(target.to_xml)).deep_symbolize_keys
      @id = result[:get_targets_response][:target][:id]
    end

    def self.exist(name, agent)
      target = Nokogiri::XML::Builder.new do |xml|
        xml.get_targets(filter: "name=#{name}")
      end
      result = Hash.from_xml(agent.sendrecv(target.to_xml)).deep_symbolize_keys
      !result[:get_targets_response][:target].nil?
    end

    def self.import_targets(user, agent)
      request = Nokogiri::XML::Builder.new do |xml|
        xml.get_targets(filter: "owner.name=#{user.name}")
      end
      results = []
      targets = Hash.from_xml(agent.sendrecv(request.to_xml)).deep_symbolize_keys
      # If there is just one target, it's not an Array
      if targets[:get_targets_response][:target].kind_of?(Array)
        targets[:get_targets_response][:target].each do |target|
          results << Target.new(target[:name], target[:hosts], agent)
        end
      else
        results << Target.new(targets[:get_targets_response][:target][:name], targets[:get_targets_response][:target][:hosts], agent)
      end
      results
    end
  end
end
