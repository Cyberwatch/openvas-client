require 'openvas_client/version'
require 'nokogiri'
require 'active_support/all'
require 'task'
require 'target'
require 'user'

module OpenVASClient
  # Main class which initiate connexion with OpenVAS API
  class OpenVASAgent
    BLOCK_SIZE = 1024 * 16

    attr_accessor :user

    def initialize(host, port, user)
      @host = host
      @port = port

      connect
      authenticate(user.name, user.password)
    end

    # set maximum for tasks, targets and users
    def max_results(value)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.modify_setting(setting_id: '5f5a8712-8017-11e1-8556-406186ea4fc5') do
          xml.name 'Rows Per Page'
          xml.value value
        end
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))
      unless result.at_css('modify_setting_response')[:status].eql?('200')
        raise OpenVASError.new(result.at_css('modify_setting_response')[:status]), result.at_css('modify_setting_response')[:status_text]
      end
    end

    # Connect with an SSL socket
    def connect
      @plain_socket = TCPSocket.open(@host, @port)
      @socket = OpenSSL::SSL::SSLSocket.new(@plain_socket, OpenSSL::SSL::SSLContext.new)

      # Enable to close socket and SSL layer together
      @socket.sync_close = true
      @socket.connect
    end

    # Get current version of OMP
    def version
      version = Nokogiri::XML(sendrecv('<get_version/>')).xpath('//version').text
      'Version : ' + version
    end

    def authenticate(user, password)
      content = Nokogiri::XML::Builder.new do |xml|
        xml.authenticate do
          xml.credentials do
            xml.username user
            xml.password password
          end
        end
      end
      result = Nokogiri::XML(sendrecv(content.to_xml))

      unless result.at_css('authenticate_response')[:status].eql?('200')
        raise OpenVASError.new(result.at_css('authenticate_response')[:status]), result.at_css('authenticate_response')[:status_text]
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

    def sync
      logger = Logger.new(STDOUT)
      sync_cert
      logger.info 'CERT Synchronisation => Request submitted'
      sync_feed
      logger.info 'FEED Synchronisation => Request submitted'
      sync_scap
      logger.info 'SCAP Synchronisation => Request submitted'
    end

    def sync_cert
      cert = Nokogiri::XML(sendrecv('<sync_cert/>'))
      unless cert.at_css('sync_cert_response')[:status].eql?('202')
        raise OpenVASError.new(result.at_css('sync_cert_response')[:status]), result.at_css('sync_cert_response')[:status_text]
      end
    end

    def sync_feed
      feed = Nokogiri::XML(sendrecv('<sync_feed/>'))
      unless feed.at_css('sync_feed_response')[:status].eql?('202')
        raise OpenVASError.new(result.at_css('sync_feed_response')[:status]), result.at_css('sync_feed_response')[:status_text]
      end
    end

    def sync_scap
      scap = Nokogiri::XML(sendrecv('<sync_scap/>'))
      unless scap.at_css('sync_scap_response')[:status].eql?('202')
        raise OpenVASError.new(result.at_css('sync_scap_response')[:status]), result.at_css('sync_scap_response')[:status_text]
      end
    end

    def sendrecv(tosend)
      @socket.syswrite(tosend)

      buffer = ''
      loop do
        last_part = @socket.sysread(BLOCK_SIZE)
        buffer += last_part
        break if last_part.size < BLOCK_SIZE
      end
      buffer
    end
  end
end
