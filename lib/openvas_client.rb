require 'openvas_client/version'
require 'nokogiri'
require 'active_support/all'

module OpenVASClient
  class OpenVASAgent

    BLOCK_SIZE = 1024*16

    def initialize(host = 'localhost', port = 9390, user = 'admin', password = 'openvas')
      @host = host
      @port = port
      @user = user
      @password = password

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

      unless result.at_css('authenticate_response')[:status].eql?('200')
        raise OpenVASError.new(result.at_css('authenticate_response')[:status]), result.at_css('authenticate_response')[:status_text]
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

    def sendrecv (tosend)
      @socket.syswrite(tosend)
      @socket.sysread(BLOCK_SIZE)
    end
  end
end
