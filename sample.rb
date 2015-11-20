#!/usr/bin/env ruby
require 'serialport'
require_relative "checksum"

# Config Parameter
cust_id = "xx"
gateway = "xxxxxxxxxx"
ioturl  = "https://xxxx/xx/xxx"
usbport = "/dev/ttyUSB0"
@serial = SerialPort.new(usbport,57600,8,1,SerialPort::NONE)

loop do
    byte = @serial.getbyte

    if byte == 0x55
	header = Array.new(4) { |b| b = @serial.getbyte }
	header_crc = @serial.getbyte 

	if header_crc == crc8(header)
	    data_len = (header[0] << 8) | header[1]
	    data = Array.new(data_len) { |b| b = @serial.getbyte }

	    opt_data_len = header[2]
	    opt_data = Array.new(opt_data_len) { |b| b = @serial.getbyte }

	    data_crc = @serial.getbyte

	    if data_crc == crc8(data + opt_data)

		value  = "%02x" % byte
		value += "%02x" % header[0]
		value += "%02x" % header[1]
		value += "%02x" % header[2]
		value += "%02x" % header[3]
		value += "%02x" % header_crc
		for num in 0..(data_len-1) do
		    value += "%02x" % data[num]
		end
		for num in 0..(opt_data_len-1) do
		    value += "%02x" % opt_data[num]
		end
		value += "%02x" % data_crc

		datetime = Time.now.strftime("%Y-%m-%d %H:%M:%S")

		# Upload Cloud
		res = `/usr/bin/curl --tlsv1 --insecure -X POST -s -S --max-time 5 #{ioturl} -F cust_id=#{cust_id} -F gateway_key="#{gateway}" -F value="#{value}" -F datetime="#{datetime}"`

		# If you want to watch response from the cloud, release the comment under line.
		# puts res
	    end
	end
    end
end

