require 'openvas_error'

module OpenVASClient
  # Define a target to scan by using its host name
  class Target
    attr_accessor :id, :name, :hosts

    def initialize(name, hosts, agent)
      @name = name
      @hosts = hosts
      @agent = agent
      if self.class.exist(name, agent)
        import
      else
        create
      end
    end

    def create
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_target do
          xml.name @name
          xml.hosts @hosts
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      unless result.at_css('create_target_response')[:status].eql?('201')
        raise OpenVASError.new(result.at_css('create_target_response')[:status]), result.at_css('create_target_response')[:status_text]
      end
      @id = result.at_css('create_target_response')[:id]
    end

    def destroy
      target = Nokogiri::XML::Builder.new do |xml|
        xml.delete_target(target_id: id)
      end
      result = Nokogiri::XML(@agent.sendrecv(target.to_xml))
      result.at_xpath('//delete_target_response/@status').text.eql?('200')
    end

    def refresh
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_targets(target_id: id)
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

    ### Setters ###

    def name=(value)
      target = Nokogiri::XML::Builder.new do |xml|
        xml.modify_target(target_id: id) do
          xml.name value
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(target.to_xml))
      unless result.at_xpath('//modify_target_response/@status').text.eql?('200')
        raise OpenVASError.new(result.at_css('modify_target_response')[:status]), result.at_css('modify_target_response')[:status_text]
      end
      @name = value
    end

    def hosts=(value)
      target = Nokogiri::XML::Builder.new do |xml|
        xml.modify_target(target_id: id) do
          xml.hosts value
          xml.exclude_hosts @hosts # To change an host, you have to exclude it first
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(target.to_xml))
      unless result.at_xpath('//modify_target_response/@status').text.eql?('200')
        raise OpenVASError.new(result.at_css('modify_target_response')[:status]), result.at_css('modify_target_response')[:status_text]
      end
      @hosts = value
    end

    ### Static Methods ###

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
      if targets[:get_targets_response][:target].is_a?(Array)
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
