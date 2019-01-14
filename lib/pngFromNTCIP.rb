require 'json'
require 'chunky_png'
module ENUM_MonochromePixelWidth
   ONE_BIT = 1
   TWO_BIT = 2
end
RGB_AMBER_RED     =     255
RGB_AMBER_GREEN   =     223
RGB_AMBER_BLUE    =     0
RGB_WHITE_RED     =     255
RGB_WHITE_GREEN   =     255
RGB_WHITE_BLUE    =     255
RGB_RED_RED       =     255
RGB_RED_GREEN     =     66
RGB_RED_BLUE      =     0
class ImageToPng
   def initialize(w, h, bw, sc, array, outName)
      @width = w
      @height = h
      @bitWidth = bw
      @scale = sc
      @array = array
      @outName = outName
   end
   def to_png
      @png = ChunkyPNG::Image.new(@width*@scale, @height*@scale, ChunkyPNG::Color::TRANSPARENT)
      case @bitWidth
         when ENUM_MonochromePixelWidth::ONE_BIT
            nX=0
            nY=0
            nBits = (@width)*@height
            nBytes = nBits/8
            nBitCounter = 0
            for nByte in 0...nBytes do
              nBitTest = 0x80
              (0...8).step(1) do |nBits|
                nValue = @array[nByte]&nBitTest
                nBitTest = nBitTest >> 1
                nValue  = nValue >> (7-nBits)
                nRed = 0
                nGreen = 0
                nBlue = 0
                case nValue
                  when 1
                   nRed = RGB_AMBER_RED
                   nGreen = RGB_AMBER_GREEN
                   nBlue = RGB_AMBER_BLUE
                  when 2
                   nRed = RGB_RED_RED
                   nGreen = RGB_RED_GREEN
                   nBlue = RGB_RED_BLUE
                  when 3
                   nRed = RGB_WHITE_RED
                   nGreen = RGB_WHITE_GREEN
                   nBlue = RGB_WHITE_BLUE
                end
                (0...@scale).each do |xs|
                  (0...@scale).each do |ys|
                    @png[nX+xs,nY+ys] = ChunkyPNG::Color.rgba(nRed, nGreen, nBlue, 128)
                  end
                end
                nX = nX+@scale
                if nX >= @width*@scale
                 nX = 0
                 nY = nY + @scale
                end
              end
            end
         when ENUM_MonochromePixelWidth::TWO_BIT
            nX=0
            nY=0
            nBits = (@width*2)*@height
            nBytes = nBits/8
            nBitCounter = 0
            for nByte in 0...nBytes do
              nBitTest = 0xC0
              (0...8).step(2) do |nBits|
                nValue = @array[nByte]&nBitTest
                nBitTest = nBitTest >>2
                nValue  = nValue >> (6-nBits)
                nRed = 0
                nGreen = 0
                nBlue = 0
                case nValue
                  when 1
                   nRed = RGB_AMBER_RED
                   nGreen = RGB_AMBER_GREEN
                   nBlue = RGB_AMBER_BLUE
                  when 2
                   nRed = RGB_RED_RED
                   nGreen = RGB_RED_GREEN
                   nBlue = RGB_RED_BLUE
                  when 3
                   nRed = RGB_WHITE_RED
                   nGreen = RGB_WHITE_GREEN
                   nBlue = RGB_WHITE_BLUE
                end
                (0...@scale).each do |xs|
                  (0...@scale).each do |ys|
                    @png[nX+xs,nY+ys] = ChunkyPNG::Color.rgba(nRed, nGreen, nBlue, 255)
                  end
                end
                nX = nX+@scale
                if nX >= @width*@scale
                 nX = 0
                 nY = nY + @scale
                end
              end
            end
      end
    @png.save(@outName.to_s+'.png', :interlace => true)
   end
end
class PNGFromNTCIP
   def initialize(w, h, bw, s, bmJson, outName)
    @signWidth = w
    @signHeight = h
    @bitsPerPixel = bw
    @scale = s
    @outName = outName
    @parsedBitmaps  = JSON.parse(bmJson)
   end
   def toPNG
    graphicType = @parsedBitmaps["graphicType"]
    bitmapArrays = @parsedBitmaps["bitmaps"]
    nPage = 1
    bitmapArrays.each do |bm|
      ntcipArray = []
      bm.each do |sample|
        ntcipArray << sample
      end
      case @bitsPerPixel
        when 1
         i2p = ImageToPng.new(@signWidth, @signHeight, ENUM_MonochromePixelWidth::ONE_BIT, @scale, ntcipArray, @outName+"-P"+nPage.to_s)
         i2p.to_png
        when 2
          i2p = ImageToPng.new(@signWidth, @signHeight, ENUM_MonochromePixelWidth::TWO_BIT, @scale, ntcipArray, @outName+"-P"+nPage.to_s)
          i2p.to_png
      end
      nPage = nPage + 1
    end
   end
end
