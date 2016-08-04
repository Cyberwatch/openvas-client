module OpenVASClient
  # define an OpenVAS User
  class User
    NB_MAX_TASKS = 3
    attr_reader :id, :name, :targets, :tasks, :password

    # Name can't contain spaces
    def initialize(name, password)
      @name = name
      @password = password
      @logger = Logger.new(STDOUT)
    end

    def connect(agent)
      if self.class.exist(@name, agent)
        import(agent)
      else
        create(agent)
      end
    end

    def populate(agent, max_size)
      @agent = agent
      @targets = OpenVASClient::Target.import_targets(self, @agent, max_size)
      @tasks = OpenVASClient::Task.import_tasks(self, @agent, max_size)
      agent.user = self
    end

    def create(agent)
      role = Nokogiri::XML::Builder.new do |xml|
        xml.get_roles(filter: 'name=User')
      end
      result = Hash.from_xml(agent.sendrecv(role.to_xml)).deep_symbolize_keys
      role_id = result[:get_roles_response][:role][:id]

      user_xml = Nokogiri::XML::Builder.new do |xml|
        xml.create_user do
          xml.name @name
          xml.password @password
          xml.role(id: role_id)
        end
      end
      result = Nokogiri::XML(agent.sendrecv(user_xml.to_xml))
      unless result.at_css('create_user_response')[:status].eql?('201')
        raise OpenVASError.new(result.at_css('create_user_response')[:status]), result.at_css('create_user_response')[:status_text]
      end
      @logger.info 'User created in OpenVAS'
      @id = result.at_css('create_user_response')[:id]
    end

    def import(agent)
      user = Nokogiri::XML::Builder.new do |xml|
        xml.get_users(filter: "name=#{@name}")
      end
      result = Hash.from_xml(agent.sendrecv(user.to_xml)).deep_symbolize_keys
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
      nil
    end

    def find_task_by_name(name)
      tasks.each do |task|
        return task if task.name.eql?(name)
      end
      nil
    end

    def clean_tasks
      @tasks = @tasks.sort_by(&:creation_time) if @tasks.length > NB_MAX_TASKS
      while @tasks.length > NB_MAX_TASKS
        @tasks.first.destroy
        @tasks.shift
      end
    end

    def destroy_all_tasks
      tasks.each do |task|
        task.destroy
        tasks.delete(task)
      end
    end

    def last_task
      @tasks.sort_by(&:creation_time).last
    end

    def destroy_task(name)
      task = find_task_by_name(name)
      task.destroy
      tasks.delete(task)
    end

    def destroy_target(name)
      target = find_target_by_name(name)
      target.destroy
      targets.delete(target)
    end

    ### Setters ###

    def name=(value)
      user = Nokogiri::XML::Builder.new do |xml|
        xml.modify_user(user_id: id) do
          xml.new_name value
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(user.to_xml))
      unless result.at_xpath('//modify_user_response/@status').text.eql?('200')
        raise OpenVASError.new(result.at_css('modify_user_response')[:status]), result.at_css('modify_user_response')[:status_text]
      end
      @name = value
    end

    def password=(value)
      user = Nokogiri::XML::Builder.new do |xml|
        xml.modify_user(user_id: id) do
          xml.password value
        end
      end
      result = Nokogiri::XML(@agent.sendrecv(user.to_xml))
      unless result.at_xpath('//modify_user_response/@status').text.eql?('200')
        raise OpenVASError.new(result.at_css('modify_user_response')[:status]), result.at_css('modify_user_response')[:status_text]
      end
      @password = value
    end

    ### Static Methods ###

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
  end
end
