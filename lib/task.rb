module OpenVASClient
  class Task
    attr_accessor :id

    def initialize(name, target, agent)
      @agent = agent
      content = Nokogiri::XML::Builder.new do |xml|
        @name = name
        @target = target
        xml.create_task {
          xml.name @name
          xml.config(id: @agent.configs('Full and fast'))
          xml.target(id: @target.id)
          xml.scanner(id: @agent.scanners())
        }
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      @id = result.at_css('create_task_response')[:id]
    end

    def destroy
      task = Nokogiri::XML::Builder.new do |xml|
        xml.delete_task(task_id: self.id)
      end
      result = Nokogiri::XML(@agent.sendrecv(task.to_xml))
      result.at_xpath('//delete_task_response/@status').text.eql?('200')
    end

    def start
      content = Nokogiri::XML::Builder.new do |xml|
        xml.start_task(task_id: self.id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      result.at_css('start_task_response report_id').text
    end

    def stop
      content = Nokogiri::XML::Builder.new do |xml|
        xml.stop_task(task_id: self.id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      result.at_xpath('//stop_task_response/@status').text.eql?('202')
    end

    def resume
      content = Nokogiri::XML::Builder.new do |xml|
        xml.resume_task(task_id: self.id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      result.xpath('//resume_task_response/@status').text.eql?('202')
    end

    # Return results in JSON format
    def results
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_results(task_id: self.id)
      end
      Hash.from_xml(Nokogiri::XML(@agent.sendrecv(content.to_xml)).to_xml).to_json
    end

    # Return report for a specific task
    def report
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: self.id, details: '1')
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      report_id = result.at_css('report')[:id]

      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_reports(report_id: report_id)
      end
      Hash.from_xml(Nokogiri::XML(@agent.sendrecv(content.to_xml)).to_xml).to_json
    end

    def all
      tasks = Nokogiri::XML(@agent.sendrecv('<get_tasks/>'))
      Hash.from_xml(Nokogiri::XML(tasks.to_xml).to_xml).to_json
    end

    def refresh
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: self.id)
      end
      Hash.from_xml(Nokogiri::XML(@agent.sendrecv(task.to_xml)).to_xml).to_json
    end
  end
end