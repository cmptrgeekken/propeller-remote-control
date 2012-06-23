CON
  Bitmap_FileHeaderSize = 14
  Bitmap_InfoHeaderSize = 40
  Bitmap_BitsPerPixel = 4
  Bitmap_NumColorPlanes = 1
  Bitmap_NumColors = (2 << (Bitmap_BitsPerPixel-1))
  Bitmap_PixelMask = (Bitmap_NumColors - 1)
  
  Bitmap_ColorTableSize = (Bitmap_NumColors * 4)
  Bitmap_PixelArrayOffset = (Bitmap_FileHeaderSize + Bitmap_InfoHeaderSize + Bitmap_ColorTableSize)
OBJ
  fs : "SD-MMC_FATEngine"
VAR
  long width,height,pixelArrayRowNumBytes
  long _fileName
PUB start : okay
  okay := false
  IF fs.FATEngineStart(0,1,2,3,-1,-1,-1,-1,-1)
    fs.mountPartition(0)
    okay := true
PUB stop
  fs.unmountPartition

PUB CreateBitmap(file_name,_width,_height) | i, j, x, y, color, pixelArraySize, fileSize  
  width  := _width
  height := _height
  _fileName := file_name

  ' Row size
  pixelArrayRowNumBytes := (Bitmap_BitsPerPixel * width + 31) / 32 * 4  
  pixelArraySize :=  pixelArrayRowNumBytes * ||height
  
  fileSize :=  Bitmap_FileHeaderSize{ 
              }+ Bitmap_InfoHeaderSize{
              }+ Bitmap_ColorTableSize{
              }+ pixelArraySize

  \fs.deleteEntry(_fileName)
  \fs.newFile(_fileName)  
    
  fs.openFile(_fileName,"W")

  { Begin Bitmap File Header }
  ' Signature
  fs.writeShort(swapEndianWord($42_4D)) ' BM
  
  ' File Size
  fs.writeLong(fileSize)
  
  ' Reserved
  fs.writeLong($0)
  
  ' Pixel Array Offset
  fs.writeLong(Bitmap_PixelArrayOffset)
  
  { End Bitmap File Header }
  
  
  { Begin BITMAPINFOHEADER }
  ' Header Size
  fs.writeLong(Bitmap_InfoHeaderSize)
  
  ' Bitmap Width
  fs.writeLong(width)
  
  ' Bitmap Height
  fs.writeLong(height)
  
  ' # of color planes (must be 1)
  fs.writeShort(Bitmap_NumColorPlanes)
  
  ' Bits per pixel
  fs.writeShort(Bitmap_BitsPerPixel)
  
  ' Compression method
  fs.writeLong(0)
  
  ' Image size
  fs.writeLong(0)
  
  ' Horizontal Resolution (pixels/meter)
  fs.writeLong(0)
  
  ' Vertical Resolution (pixels/meter)
  fs.writeLong(0)
  
  ' # of colors in the color palette
  fs.writeLong(Bitmap_NumColors)
  
  ' # of important colors used (0 for all)
  fs.writeLong(0)

  { Begin Color Table }
  repeat i from 0 to Bitmap_NumColors-1
    color := i * 255 / (Bitmap_NumColors-1)
    repeat 3
      fs.writeByte(color)
    fs.writeByte(0)
  { End Color Table }

  repeat height * pixelArrayRowNumBytes / 4
    fs.writeLong($FFFFFFFF)

PUB close
  fs.unmountPartition

PUB reopen
  fs.mountPartition(0)
  fs.openFile(_fileName,"W")

PUB writePixel(x,y,color) | fileOffset, currentShift, currentValue
  fileOffset := (Bitmap_PixelArrayOffset + ((y-1)*pixelArrayRowNumBytes + (x-1)*Bitmap_BitsPerPixel/8))
  fs.fileSeek(fileOffset)
  if Bitmap_BitsPerPixel == 32
    result := fs.writeLong(color)
  elseif Bitmap_BitsPerPixel == 24
    result := fs.writeShort(color >> 8) + fs.writeByte(color)
  elseif Bitmap_BitsPerPixel == 16
    fs.writeShort(color)
  elseif Bitmap_BitsPerPixel == 8
    result := fs.writeByte(color)
  elseif Bitmap_BitsPerPixel < 8     
    currentShift := Bitmap_BitsPerPixel * (8 / Bitmap_BitsPerPixel - (x-1) // (8 / Bitmap_BitsPerPixel) - 1)
    currentValue := (fs.readByte & !(Bitmap_PixelMask << currentShift)) | ((color & Bitmap_PixelMask) << currentShift)
    fs.fileSeek(fileOffset)
    result := fs.writeByte(currentValue)

PUB flush
  fs.flushData    

PRI swapEndianLong(orig) : swapped
  swapped := ((orig >> 24) & $FF) | ((orig >> 16) & $FF00) | ((orig & $FF00) << 8) | ((orig & $FF) << 24)
  
PRI swapEndianWord(orig) : swapped
  swapped := ((orig >> 8) & $FF) | ((orig & $FF) << 8)
  
PRI swapEndianByte(orig) : swapped
  swapped := ((orig >> 4) & $F) | ((orig & $F) << 4)