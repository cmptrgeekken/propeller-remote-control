'**************************************************************
'* p2os                                                     *
'**************************************************************
CON
  HEADER0      = 250
  HEADER1      = 251

  DT_INT    = $3B
  DT_NINT   = $1B
  DT_STRING = $2B
OBJ
  serial : "FullDuplexSerial"
VAR
  ' Client Command packet format:
  '  --------------------------------------------------------------------------------------------
  '  |   Header (2b)  | Ct (1b)| Cmd (1b) | Data Type (1b) | Data (0-244b) ... | Checksum (2b)  |
  '  --------------------------------------------------------------------------------------------
  byte packet[256]
  byte packet_size
  byte current_offset
PUB init(rx_pin,tx_pin,baud_rate)
  serial.Start(rx_pin,tx_pin,%0000,baud_rate)

PUB SendPacket | i
  i := 0
  repeat i from 0 to packet_size-1
    serial.tx(packet[i])

PUB ReceivePacket(ignore_checksum)
  ReceivePacketTimeout(ignore_checksum,0)

PUB ReceivePacketTimeout(ignore_checksum,timeout) : okay | i, data_size, rcvd_chksum, calcd_chksum
  okay := true
  ' For performance reasons, don't null the packet.
  ' If handled appropriately, shouldn't be necessary anyways
  ' as we always know the size of the packet.
  'bytefill(@packet,0,256)
  'repeat
    ' Read bytes until the appropriate start
    ' byte is found
   ' repeat until serial.rxcheck == HEADER0
   '   waitcnt(clkfreq / 1_000 + cnt)
   
    ' Read in the header information
    IF timeout == 0
      repeat until serial.rxcheck == HEADER0
      packet[0] := HEADER0        ' Header 0
    ELSE
        IF packet[0] := serial.rxtime(timeout) == -1
            return okay := false
    packet[1] := serial.rx        ' Header 1                        
    packet[2] := serial.rx        ' Data Size

    data_size := packet[2]
    'IF NOT ignore_checksum AND data_size > 3
    '  data_size -= 2

    'IFNOT packet[0] == HEADER0 AND packet[1] == HEADER1
    '  RETURN false
                                
    REPEAT i FROM 0 TO data_size-1
      packet[i+3] := serial.rx

    'IFNOT ignore_checksum     
    '  rcvd_chksum := serial.rx << 8 | serial.rx
    '  calcd_chksum := CalcChecksum(false)
    '  IF rcvd_chksum == calcd_chksum
    '    quit
    'ELSE
    '  quit
  
  
  
PUB BuildPacket(command,data_type,value) | chksum
  IF data_type == DT_STRING
    return

  BuildPacketHeader(4)

  packet[3] := command
  packet[4] := data_type
  packet[5] := value & $FF
  packet[6] := (value >> 8) & $FF

  CalcChecksum(true)

  return @packet

PUB BuildPacketInt(command,value)
  ~~value
  IF value < 0
    return BuildPacket(command,DT_NINT,||value)
  ELSE
    return BuildPacket(command,DT_INT,||value)

PUB BuildPacketUInt(command,value)
  return BuildPacket(command,DT_INT,value)
  
PUB CalcChecksum(store_in_pckt) : c | i, n
{{ Call only after placing all data in the packet }}
  c := 0
  i := 3
  n := packet[2]-2
  
  repeat while n > 1
    c += packet[i] << 8 | packet[i+1]
    c &= $FFFF
    n -= 2
    i += 2
  if n > 0
    c ^= packet[i] & $FF
  
  IF store_in_pckt
    packet[packet_size-2] := c >> 8
    packet[packet_size-1] := c & $FF
    
PUB Type
  RETURN packet[3]
  
PUB GetInt(offset) : value
  IF offset == -1
      offset := current_offset
  current_offset := offset + 2
  
  value := packet[offset] | packet[offset+1] << 8
  
  ~~value

PUB GetByte(offset) : value
  IF offset == -1
      offset := current_offset
  current_offset := offset + 1
  
  value := packet[offset]
  ~value
  
  RETURN value

PUB GetString(bufferAddr,maxLength,offset,initialByteHasLength) | i, value
  {{ Reads a string from the packet. Ensure that the
     buffer length is at least one greater than the max
     length to allow for null termination.
     
     Returns: The actual length of the string
  }}
  IF offset == -1
    offset := current_offset
  
  
  IF initialByteHasLength == true
    abort
  ELSE
    ResetCounter(offset)

    i := 0
    repeat
      value := GetByte(-1)
      IF NOT bufferAddr == 0 AND i < maxLength
        byte[bufferAddr][i] := value
      i++
    until value == 0
    'byte[bufferAddr][i] := 0
    RETURN i

PUB ResetCounter(value)
  current_offset := value

PUB GetCounter
  RETURN current_offset

PRI BuildPacketHeader(data_size)
  packet[0] := HEADER0
  packet[1] := HEADER1
  packet[2] := data_size + 2

  packet_size := data_size + 5