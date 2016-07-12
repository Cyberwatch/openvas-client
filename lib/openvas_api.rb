require 'openvas_api/version'
require 'nokogiri'
require 'active_support/all'

module OpenVASApi
  class OpenVASAgent

    def initialize(host = 'localhost', port = 9390, user = 'admin', password = 'openvas')
      @host = host
      @port = port
      @user = user
      @password = password
      @buffsize = 16384 # TODO: Set the optimal value

      connect()
      authenticate()
    end

    # Connect with an SSL socket
    def connect
      @plain_socket = TCPSocket.open(@host, @port)
      @socket = OpenSSL::SSL::SSLSocket.new(@plain_socket, OpenSSL::SSL::SSLContext.new())

      # Enable to close socket and SSL layer together
      @socket.sync_close = true
      @socket.connect
    end

    # Get current version of OMP
    def version
      version = Nokogiri::XML(sendrecv('<get_version/>')).xpath('//version').text
      'Version : ' + version
    end

    def authenticate
      content = Nokogiri::XML::Builder.new do |xml|
        xml.authenticate {
          xml.credentials {
            xml.username @user
            xml.password @password
          }
        }
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      if result.xpath('//authenticate_response/@status').text.eql?('200')
        'Authentication OK'
      else
        'Authentication KO'
      end
    end

    def users
      users = Nokogiri::XML(sendrecv('<get_users/>'))
      users.css('user name').each do |name|
        p 'User : ' + name.text
      end
    end

    # Enable to choose between different types of scan
    def configs(conf_name)
      users = Nokogiri::XML(sendrecv('<get_configs/>'))
      users.css('config').each do |config|
        return config[:id] if config.xpath('./name').text.eql?(conf_name)
      end
    end

    # Get default OpenVas scanner
    def scanners
      users = Nokogiri::XML(sendrecv('<get_scanners/>'))
      users.css('scanner')[0][:id]
    end

    def create_target(name, hosts)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_target {
          xml.name name
          xml.hosts hosts
        }
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      if result.at_css('create_target_response')[:value].eql?(200)
        result.at_css('create_target_response')[:id]
      else
        result.at_css('create_target_response')[:status_text]
      end
    end

    def delete_target(target_id)
      target = Nokogiri::XML::Builder.new do |xml|
        xml.delete_target(target_id: target_id)
      end
      result = Nokogiri::XML(sendrecv(target.to_xml))
      result.at_xpath('//delete_target_response/@status').text.eql?('200')
    end

    def targets
      targets = Nokogiri::XML(sendrecv('<get_targets/>'))
      Hash.from_xml(Nokogiri::XML(targets.to_xml).to_xml).to_json
    end

    def target(id)
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_targets(target_id: id)
      end
      Hash.from_xml(Nokogiri::XML(sendrecv(task.to_xml)).to_xml).to_json
    end

    def tasks
      tasks = Nokogiri::XML(sendrecv('<get_tasks/>'))
      Hash.from_xml(Nokogiri::XML(tasks.to_xml).to_xml).to_json
    end

    def task(id)
      task = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: id)
      end
      Hash.from_xml(Nokogiri::XML(sendrecv(task.to_xml)).to_xml).to_json
    end

    # Return task's id
    def create_task(task_name, target_id, comment = '')
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_task {
          xml.name task_name
          xml.comment comment
          xml.config(id: configs('Full and fast'))
          xml.target(id: target_id)
          xml.scanner(id: scanners())
        }
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('create_task_response')[:id]
    end

    def delete_task(task_id)
      task = Nokogiri::XML::Builder.new do |xml|
        xml.delete_task(task_id: task_id)
      end
      result = Nokogiri::XML(sendrecv(task.to_xml))
      result.at_xpath('//delete_task_response/@status').text.eql?('200')
    end

    def start_task(task_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.start_task(task_id: task_id)
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('start_task_response report_id').text
    end

    def stop_task(task_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.stop_task(task_id: task_id)
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      if result.at_xpath('//stop_task_response/@status').text.eql?('202')
        'Arrêt OK'
      else
        'Arrêt KO'
      end
    end

    # Get report ID for a specific task
    def task_report(task_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: task_id, details: '1')
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('report')[:id]
    end

    def resume_task(task_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.resume_task(task_id: task_id)
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      if result.xpath('//resume_task_response/@status').text.eql?('202')
        'Pause OK'
      else
        'Pause KO'
      end
    end

    # Return report in JSON format
    def report(report_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_reports(report_id: report_id)
      end
      Hash.from_xml(Nokogiri::XML(sendrecv(content.to_xml)).to_xml).to_json
    end

    # Return results in JSON format
    def results(task_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_results(task_id: task_id)
      end
      Hash.from_xml(Nokogiri::XML(sendrecv(content.to_xml)).to_xml).to_json
    end

    def sendrecv (tosend)
      connect() unless @socket
      @socket.syswrite(tosend)
      @socket.sysread(@buffsize)
    end
  end
end
