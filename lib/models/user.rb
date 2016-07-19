module OpenVASClient
  class User
    NB_MAX_TASKS = 3
    attr_reader :id, :name, :targets, :tasks

    # Name can't contain spaces
    def initialize(name, password, agent)
      @agent = agent
      @name = name
      @password = password
      unless self.class.exist(name, agent)
        create
      else
        import
      end
      @targets = OpenVASClient::Target.import_targets(self, @agent)
      @tasks = OpenVASClient::Task.import_tasks(self, @agent)
    end

    def create
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

    def import
      user = Nokogiri::XML::Builder.new do |xml|
        xml.get_users(filter: "name=#{@name}")
      end
      result = Hash.from_xml(@agent.sendrecv(user.to_xml)).deep_symbolize_keys
      @id = result[:get_users_response][:user][:id]
    end

    def create_task(name, target)
      task = OpenVASClient::Task.new(name, target, @agent)
      self.tasks << task
      task
    end

    def create_target(name, hosts)
      target = OpenVASClient::Target.new(name, hosts, @agent)
      self.targets << target
      target
    end

    def find_target_by_name(name)
      self.targets.each do |target|
        return target if target.name.eql?(name)
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
      users.css('user name').each do |name|
        p 'User : ' + name.text
      end
    end

    def clean_tasks
      if @tasks.length > NB_MAX_TASKS
        @tasks = @tasks.sort_by(&:creation_time)
      end
      while @tasks.length > NB_MAX_TASKS
        @tasks.first.destroy
        @tasks.shift
      end
    end
  end
end
