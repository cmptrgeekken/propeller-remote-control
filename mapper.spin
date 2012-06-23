OBJ
  bmp : "bitmap_writer"    
VAR
  long width,height

  byte cog
  byte stack[200]

  byte _isOpen 

PUB start(_width,_height) : okay
  width := _width
  height := _height

  
  okay := bmp.start
  bmp.flush

PUB stop
  bmp.stop
  IF cog
    cogstop(cog~ - 1)

PUB New(file_name) : okay
  okay := bmp.CreateBitmap(file_name,width,height)
  _isOpen~~
  

PUB Close
  bmp.close
  _isOpen~

PUB Open
  bmp.reopen
  _isOpen~~


PUB IsOpen
  RETURN _isOpen

PUB DrawPoint(x,y,color)
  IF x > 0 AND x =< width AND y > 0 AND y =< height
    bmp.writePixel(x,y,color)