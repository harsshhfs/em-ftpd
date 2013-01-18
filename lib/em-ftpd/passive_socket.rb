require 'socket'
require 'stringio'

require 'eventmachine'
require 'em/protocols/line_protocol'

module EM::FTPD

  # An eventmachine module for opening a socket for the client to connect
  # to and send a file
  #
  class PassiveSocket < EventMachine::Connection 
    include EM::Deferrable
    include BaseSocket
    

    def self.start(host, control_server)
     
     puts @securechannel
           
       if @securechannel == true  
           
           start_tls(:private_key_file => '/tmp/server.key', :cert_chain_file => '/tmp/server.crt', :verify_peer => false)
             EventMachine.start_server(host, 0, self) do |conn|
              control_server.datasocket = conn
             end 
       else
           EventMachine.start_server(host, 0, self) do |conn|
            control_server.datasocket = conn
           end
      end
    end

    # stop the server with signature "sig"
    def self.stop(sig)
      EventMachine.stop_server(sig)
    end

    # return the port the server with signature "sig" is listening on
    #
    def self.get_port(sig)
      Socket.unpack_sockaddr_in( EM.get_sockname( sig ) ).first
    end

    
  end
end
