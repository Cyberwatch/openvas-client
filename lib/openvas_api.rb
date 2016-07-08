require 'openvas_api/version'
require 'nokogiri'
require 'active_support/all'

module OpenvasApi
  class OpenVASOMP

    def initialize(host = 'localhost', port = 9390, user = 'admin', password = 'openvas')
      @host = host
      @port = port
      @user = user
      @password = password
      @buffsize = 16384

      connect()
      authenticate()
    end

    def connect
      @plain_socket = TCPSocket.open(@host, @port)
      @socket = OpenSSL::SSL::SSLSocket.new(@plain_socket, OpenSSL::SSL::SSLContext.new())

      # Enable to close socket and SSL layer together
      @socket.sync_close = true
      @socket.connect
    end

    def version
      version = Nokogiri::XML(sendrecv('<get_version/>')).xpath('//version').text
      p 'Version : ' + version
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
        p 'Authentication OK'
      else
        p 'Authentication KO'
      end
    end

    def users
      users = Nokogiri::XML(sendrecv('<get_users/>'))
      users.css('user name').each do |name|
        p 'User : ' + name.text
      end
    end

    def configs
      users = Nokogiri::XML(sendrecv('<get_configs/>'))
      users.css('config').each do |config|
        # Get Full and fast config by default
        return config[:id] if config.xpath('./name').text.eql?('Full and fast')
      end
    end

    def scanners
      users = Nokogiri::XML(sendrecv('<get_scanners/>'))
      # Get default Scanner
      p users.css('scanner')[0][:id]
    end

    def create_target(name, hosts)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_target {
          xml.name name
          xml.hosts hosts
        }
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('create_target_response')[:id]
    end

    def create_task(task_name, target_name, host, comment = '')
      content = Nokogiri::XML::Builder.new do |xml|
        xml.create_task {
          xml.name task_name
          xml.comment comment
          xml.config(id: configs())
          xml.target(id: create_target(target_name, host))
          xml.scanner(id: scanners())
        }
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('create_task_response')[:id]
    end

    # Get report ID for a specific task
    def task_report(task_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_tasks(task_id: task_id, details: '1')
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('report')[:id]
    end

    def start_task(id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.start_task(task_id: id)
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      result.at_css('start_task_response report_id').text
    end

    def report(report_id)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.get_reports(report_id: report_id)
      end
      Hash.from_xml(Nokogiri::XML(sendrecv(content.to_xml)).to_xml).to_json
    end

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
