require 'socket'

module RemoteSyslogLogger
  class UdpSender
    def initialize(remote_hostname, remote_port, options = {})
      @remote_hostname = remote_hostname
      @remote_port     = remote_port
      @whinyerrors     = options[:whinyerrors]
      @socket = UDPSocket.new
    end

    def transmit(message)
      message.split(/\r?\n/).each do |line|
        begin
          next if line =~ /^\s*$/
          packet = assemble_packet(line)
          @socket.send(packet, 0, @remote_hostname, @remote_port)
        rescue
          $stderr.puts "#{self.class} error: #{$!.class}: #{$!}\nOriginal message: #{line}"
          raise if @whinyerrors
        end
      end
    end

    # Make this act a little bit like an `IO` object
    alias_method :write, :transmit

    def close
      @socket.close
    end

    private
    def assemble_packet(data, max_size = 1024)
      if string_bytesize(data) > max_size
        data = data.slice(0, max_size)
        while string_bytesize(data) > max_size
          data = data.slice(0, data.length - 1)
        end
      end

      "#{data}\n"
    end

    def string_bytesize(string)
      if string.respond_to?(:bytesize)
        string.bytesize
      else
        string.length
      end
    end
  end
end
