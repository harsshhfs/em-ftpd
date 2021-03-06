require 'socket'
require 'stringio'

require 'eventmachine'
require 'em/protocols/line_protocol'

module EM::FTPD

  # An eventmachine module for opening a socket for the client to connect
  # to and send a file
  #
  class PassiveSocket < EM::Connection
    include EM::Deferrable
    include BaseSocket
    include EM::Protocols::LineProtocol
    
    

    def self.start(host, control_server)
     
      puts $securechannel           
       if $securechannel == true              
           def post_init
                close_connection_after_writing                
                start_tls(:private_key_file => '/tmp/server.key', :cert_chain_file => '/tmp/server.crt', :verify_peer => false)
           end             
           
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
