module OpenVASClient
  # define an OpenVAS User
  class User
    NB_MAX_TASKS = 3
    attr_reader :id, :name, :targets, :tasks

    # Name can't contain spaces
    def initialize(name, password, agent)
      @agent = agent
      @name = name
      @password = password
      if self.class.exist(name, agent)
        import
      else
        create
      end
      @targets = OpenVASClient::Target.import_targets(self, @agent)
      @tasks = OpenVASClient::Task.import_tasks(self, @agent)
    end

    def create
      user_xml = Nokogiri::XML::Builder.new do |xml|
        xml.create_user do
          xml.name @name
          xml.password @password
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(user_xml.to_xml))
      unless result.at_css('create_user_response')[:status].eql?('201')
        raise OpenVASError.new(result.at_css('create_user_response')[:status]), result.at_css('create_user_response')[:status_text]
      end
      @id = result.at_css('create_user_response')[:id]
    end

    def import
      user = Nokogiri::XML::Builder.new do |xml|
        xml.get_users(filter: "name=#{@name}")
      end
      result = Hash.from_xml(@agent.sendrecv(user.to_xml)).deep_symbolize_keys
      @id = result[:get_users_response][:user][:id]
    end

    def create_task(name, target)
      task = OpenVASClient::Task.new(name, target, @agent)
      tasks << task
      task
    end

    def create_target(name, hosts)
      target = OpenVASClient::Target.new(name, hosts, @agent)
      targets << target
      target
    end

    def find_target_by_name(name)
      targets.each do |target|
        return target if target.name.eql?(name)
      end
    end

    def find_task_by_name(name)
      tasks.each do |task|
        return task if task.name.eql?(name)
      end
    end

    def self.exist(name, agent)
      user = Nokogiri::XML::Builder.new do |xml|
        xml.get_users(filter: "name=#{name}")
      end
      result = Hash.from_xml(agent.sendrecv(user.to_xml)).deep_symbolize_keys
      !result[:get_users_response][:user].nil?
    end

    def self.users(agent)
      users = Nokogiri::XML(agent.sendrecv('<get_users/>'))
      result = Hash.from_xml(users.to_xml).deep_symbolize_keys
      logger = Logger.new(STDOUT)
      result[:get_users_response][:user].each do |user|
        logger.info 'User => id: ' + user[:id] + ' name: ' + user[:name]
      end
    end

    def self.destroy(id, agent)
      user = Nokogiri::XML::Builder.new do |xml|
        xml.delete_user(user_id: id)
      end
      result = Nokogiri::XML(agent.sendrecv(user.to_xml))
      result.at_xpath('//delete_user_response/@status').text.eql?('200')
    end

    def clean_tasks
      @tasks = @tasks.sort_by(&:creation_time) if @tasks.length > NB_MAX_TASKS
      while @tasks.length > NB_MAX_TASKS
        @tasks.first.destroy
        @tasks.shift
      end
    end
  end
end
