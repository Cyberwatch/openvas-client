module OpenVASClient
  class Task
    attr_accessor :id

    def initialize(name, target, agent)
      @agent = agent
      @name = name
      @target = target
      unless self.class.exist(name, agent)
        create
      else
        import
      end
    end

    def create
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_task {
          xml.name @name
          xml.config(id: @agent.configs('Full and fast'))
          xml.target(id: @target.id)
          xml.scanner(id: @agent.scanners)
        }
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      @id = result.at_css('create_task_response')[:id]
    end

    def import
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(filter: "name=#{@name}")
      end
      result = Hash.from_xml(@agent.sendrecv(task.to_xml)).deep_symbolize_keys
      @id = result[:get_tasks_response][:task][:id]
    end

    # Destroy the same object multiple times won't raise an error
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
      result.at_xpath('//start_task_response/@status').text.eql?('202')
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
      unless result.at_css('resume_task_response')[:status].eql?('202')
        raise OpenVASError.new(result.at_css('resume_task_response')[:status]), result.at_css('resume_task_response')[:status_text]
      end
    end

    # Return results in JSON format
    def results
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_results(task_id: self.id)
      end
      Hash.from_xml(@agent.sendrecv(content.to_xml)).deep_symbolize_keys
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
      Hash.from_xml(@agent.sendrecv(content.to_xml)).deep_symbolize_keys
    end

    def status
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: self.id)
      end
      Hash.from_xml(@agent.sendrecv(task.to_xml)).deep_symbolize_keys
    end

    def self.exist(name, agent)
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(filter: "name=#{name}")
      end
      result = Hash.from_xml(agent.sendrecv(task.to_xml)).deep_symbolize_keys
      !result[:get_tasks_response][:task].nil?
    end

    def self.import_tasks(user, agent)
      request = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(filter: "owner.name=#{user.name}")
      end
      results = []
      tasks = Hash.from_xml(agent.sendrecv(request.to_xml)).deep_symbolize_keys
      # If there is just one task, it's not an Array
      if tasks[:get_tasks_response][:task].kind_of?(Array)
        tasks[:get_tasks_response][:task].each do |target|
          #results << Task.new(task[:name], , agent)
        end
      else
        p tasks
        #results << Task.new(tasks[:get_tasks_response][:task][:name], , agent)
      end
      results
    end
  end
end