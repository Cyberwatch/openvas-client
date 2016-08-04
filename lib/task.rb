module OpenVASClient
  # Define a Task which will perform scans according to a specific target
  class Task
    attr_accessor :id, :creation_time, :name

    MAX_RESULTS = 100 # Maximum number of results

    def initialize(name, target, agent)
      @agent = agent
      @name = name
      @target = target
      if self.class.exist(name, agent)
        import
      else
        create
      end
    end

    def create
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_task do
          xml.name @name
          xml.config(id: @agent.configs('Full and fast'))
          xml.target(id: @target.id)
          xml.scanner(id: @agent.scanners)
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      @id = result.at_css('create_task_response')[:id]
      @creation_time = result.at_css('create_task_response')[:creation_time]
    end

    def import
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(filter: "name=#{@name}")
      end
      result = Hash.from_xml(@agent.sendrecv(task.to_xml)).deep_symbolize_keys
      @id = result[:get_tasks_response][:task][:id]
      @creation_time = result[:get_tasks_response][:task][:creation_time]
    end

    # Destroy the same object multiple times won't raise an error
    def destroy
      task = Nokogiri::XML::Builder.new do |xml|
        xml.delete_task(task_id: id)
      end
      result = Nokogiri::XML(@agent.sendrecv(task.to_xml))
      result.at_xpath('//delete_task_response/@status').text.eql?('200')
    end

    def start
      content = Nokogiri::XML::Builder.new do |xml|
        xml.start_task(task_id: id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      result.at_xpath('//start_task_response/@status').text.eql?('202')
    end

    def stop
      content = Nokogiri::XML::Builder.new do |xml|
        xml.stop_task(task_id: id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      result.at_xpath('//stop_task_response/@status').text.eql?('202')
    end

    def resume
      content = Nokogiri::XML::Builder.new do |xml|
        xml.resume_task(task_id: id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      unless result.at_css('resume_task_response')[:status].eql?('202')
        raise OpenVASError.new(result.at_css('resume_task_response')[:status]), result.at_css('resume_task_response')[:status_text]
      end
    end

    # Return results in JSON format
    def results
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_results(filter: "first=1 rows=#{MAX_RESULTS} task_id=#{id}", details: 1)
      end
      Hash.from_xml(@agent.sendrecv(content.to_xml)).deep_symbolize_keys
    end

    # Return report for a specific task
    def report
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: id)
      end
      result = Nokogiri::XML(@agent.sendrecv(content.to_xml))
      report_id = result.at_css('report')[:id]
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_reports(report_id: report_id)
      end
      Hash.from_xml(@agent.sendrecv(content.to_xml)).deep_symbolize_keys
    end

    def progress
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: id)
      end
      result = Hash.from_xml(@agent.sendrecv(task.to_xml)).deep_symbolize_keys
      result[:get_tasks_response][:task][:progress]
    end

    ### Setters ###
    # @hosts can't be set

    def name=(value)
      task = Nokogiri::XML::Builder.new do |xml|
        xml.modify_task(task_id: id) do
          xml.name value
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(task.to_xml))
      unless result.at_xpath('//modify_task_response/@status').text.eql?('200')
        raise OpenVASError.new(result.at_css('modify_task_response')[:status]), result.at_css('modify_task_response')[:status_text]
      end
      @name = value
    end

    ### Static Methods ###

    def self.exist(name, agent)
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(filter: "name=#{name}")
      end
      result = Hash.from_xml(agent.sendrecv(task.to_xml)).deep_symbolize_keys
      !result[:get_tasks_response][:task].nil?
    end

    def self.import_tasks(user, agent, max_tasks)
      request = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(filter: "first=1 rows=#{max_tasks}")
      end
      results = []
      tasks = Hash.from_xml(agent.sendrecv(request.to_xml)).deep_symbolize_keys
      # If there is just one task, it's not an Array
      if tasks[:get_tasks_response][:task].is_a?(Array)
        tasks[:get_tasks_response][:task].each do |task|
          results << Task.new(task[:name], user.find_target_by_name(task[:target][:name]), agent)
        end
      else
        task = tasks[:get_tasks_response][:task]
        results << Task.new(task[:name], user.find_target_by_name(task[:target][:name]), agent) unless task.nil?
      end
      results
    end

    def self.count(agent)
      request = Nokogiri::XML(agent.sendrecv('<get_tasks/>'))
      task_count = Hash.from_xml(request.to_xml).deep_symbolize_keys
      task_count[:get_tasks_response][:task_count].to_i
    end
  end
end
