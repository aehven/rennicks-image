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
AMSIG_AMBER_PIXEL = 1
AMSIG_RED_PIXEL = 2
AMSIG_WHITE_PIXEL = 3
CLASSIC_COLOR_BLACK = 0
CLASSIC_COLOR_RED = 1
CLASSIC_COLOR_WHITE = 7
CLASSIC_COLOR_AMBER = 9
class ImageToPng
   def initialize(w, h, bw, sc, array, outName)
      @width = w
      @height = h
      @bitWidth = bw
      @scale = sc
      @array = array
      @outName = outName
   end
   def to_png(bigPng=nil, pageWidth=0, pageHeight=0, pageArray=nil, xOffset=0, yOffset=0)
      if nil == bigPng
         @png = ChunkyPNG::Image.new(@width*@scale, @height*@scale, ChunkyPNG::Color::TRANSPARENT)
      else
         @png = bigPng
      end
      if nil != pageArray
         @array = pageArray
      end
      if 0 == pageWidth
       pageWidth = @width
      end
      if 0 == pageHeight
       pageHeight = @height
      end
      case @bitWidth
         when ENUM_MonochromePixelWidth::ONE_BIT
            nX=0
            nY=0
            nBits = pageHeight*pageWidth
            nBytes = nBits/8
            for nByte in 0...nBytes do
              nBitTest = 0x80
              (0...8).step(1) do |nBits|
                nRed = 0
                nGreen = 0
                nBlue = 0
                if 0 != @array[nByte]&nBitTest
                   nRed = RGB_AMBER_RED
                   nGreen = RGB_AMBER_GREEN
                   nBlue = RGB_AMBER_BLUE
                end
                nBitTest = nBitTest >> 1
                (0...@scale).each do |xs|
                  (0...@scale).each do |ys|
                    @png[xOffset+nX+xs,yOffset+nY+ys] = ChunkyPNG::Color.rgba(nRed, nGreen, nBlue, 255)
                  end
                end
                nX = nX+@scale
                if nX >= pageWidth*@scale
                 nX = 0
                 nY = nY + @scale
                end
              end
            end
         when ENUM_MonochromePixelWidth::TWO_BIT
            nX=0
            nY=0
            nBits = pageHeight*pageWidth
            nBytes = nBits/4
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
                  when AMSIG_AMBER_PIXEL

                   nRed = RGB_AMBER_RED
                   nGreen = RGB_AMBER_GREEN
                   nBlue = RGB_AMBER_BLUE

                  when AMSIG_RED_PIXEL

                   nRed = RGB_RED_RED
                   nGreen = RGB_RED_GREEN
                   nBlue = RGB_RED_BLUE

                  when AMSIG_WHITE_PIXEL

                   nRed = RGB_WHITE_RED
                   nGreen = RGB_WHITE_GREEN
                   nBlue = RGB_WHITE_BLUE

                end
                (0...@scale).each do |xs|
                  (0...@scale).each do |ys|
                    @png[xOffset+nX+xs,yOffset+nY+ys] = ChunkyPNG::Color.rgba(nRed, nGreen, nBlue, 255)
                  end
                end
                nX = nX+@scale
                if nX >= pageWidth*@scale
                 nX = 0 
                 nY = nY + @scale
                end
              end
            end
      end
    @png.save(@outName.to_s+'.png', :interlace => true)
   end
end
class PreviewImageToPng
   def initialize(w, h, sc, bitmap, outName)
      @width = w
      @height = h
      @scale = sc
      @bitmap = bitmap
      @outName = outName
   end
   def to_png(bigPng=nil, pageWidth=0, pageHeight=0, bitmap=nil, xOffset=0, yOffset=0)
      if nil == bigPng
         @png = ChunkyPNG::Image.new(@width*@scale, @height*@scale, ChunkyPNG::Color::TRANSPARENT)
      else
         @png = bigPng
      end
      if nil != bitmap
         @bitmap = bitmap
      end
      if 0 == pageWidth
       pageWidth = @width
      end
      if 0 == pageHeight
       pageHeight = @height
      end
      nX=0
      nY=0
      @bitmap.each do |row|
         nX = 0
         row.each do |pixel|
             nRed = 0
             nGreen = 0
             nBlue = 0
             case pixel
               when CLASSIC_COLOR_AMBER

                nRed = RGB_AMBER_RED
                nGreen = RGB_AMBER_GREEN
                nBlue = RGB_AMBER_BLUE

               when CLASSIC_COLOR_RED

                nRed = RGB_RED_RED
                nGreen = RGB_RED_GREEN
                nBlue = RGB_RED_BLUE

               when CLASSIC_COLOR_WHITE

                nRed = RGB_WHITE_RED
                nGreen = RGB_WHITE_GREEN
                nBlue = RGB_WHITE_BLUE

             end
             (0...@scale).each do |xs|
               (0...@scale).each do |ys|
                 @png[xOffset+nX+xs,yOffset+nY+ys] = ChunkyPNG::Color.rgba(nRed, nGreen, nBlue, 255)
               end
             end
             nX = nX+@scale
             if nX >= pageWidth*@scale
              nX = 0 
             end
         end
            nY = nY + @scale
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
    bitmapArrays = @parsedBitmaps["bitmaps"]
    nPage = 1

    ######
    # create a new .png file for each page
    #####
    bitmapArrays.each do |bm|
      ntcipArray = []
      bm.each do |sample|
        ntcipArray << sample
      end
      bppEnum =  ENUM_MonochromePixelWidth::ONE_BIT
      if 2 == @bitsPerPixel
         bppEnum =  ENUM_MonochromePixelWidth::TWO_BIT
      end
      i2p = ImageToPng.new(@signWidth, @signHeight, bppEnum, @scale, ntcipArray, @outName+"-P"+nPage.to_s)
      i2p.to_png
      nPage = nPage + 1
    end
   end
end
#######
# generate a PNG file 
# from  a preview bitmap
#####
class PNGFromPreview
   def initialize(s, bmJson, outName)
    @scale = s
    @outName = outName
    @parsedBitmaps  = JSON.parse(bmJson)
    @width = @parsedBitmaps["width"]
    @height = @parsedBitmaps["height"]
   end
   def toPNG
    bitmapArray = @parsedBitmaps["bits"]
    bppEnum =  ENUM_MonochromePixelWidth::TWO_BIT

    ######
    # create a new .png file for each page
    #####
    i2p = PreviewImageToPng.new(@width, @height, @scale, bitmapArray, @outName)
    i2p.to_png
   end
end

#######
# this is how the images will be layed out
# the code below will handle up to 9 pages
# we may need to add the ability to handle more later
####
# 1
# [p]
# 
# 2
# [p p]
# 
# 3
# [p p]
# [p  ]
# 
# 4
# [p p]
# [p p]
# 
# 5
# [p p]
# [p p]
# [p  ]
# 
# 6
# [p p]
# [p p]
# [p p]
# 
# 7
# [p p p]
# [p p p]
# [p    ]
# 
# 8
# [p p p]
# [p p p]
# [p p  ]
# 
# 9
# [p p p]
# [p p p]
# [p p p]
# 
# 10
# [p p p p]
# [p p p p]
# [p p    ]
# 
# 11
# [p p p p]
# [p p p p]
# [p p p  ]
# 
# 12
# [p p p p]
# [p p p p]
# [p p p p]
#######
class PanelDefs
   def initialize(width, height, scale, borderSize, nImages)
    @bmPositions = []
    @pngWidth = 0
    @pngHeight = 0

    #####
    # calculate positions for each page 
    # in the encompassing image
    #####
    case nImages
      when 1
         @bmPositions << [borderSize*scale, borderSize*scale]
         @pngWidth = ((borderSize*2)+width)*scale
         @pngHeight = ((borderSize*2)+height)*scale

      when 2
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @pngWidth = ((borderSize*3)+(width*2))*scale
         @pngHeight = ((borderSize*2)+height)*scale

      when 3
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @pngWidth = ((borderSize*3)+(width*2))*scale
         @pngHeight = ((borderSize*3)+(height*2))*scale

      when 4
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*2)+height)*scale]
         @pngWidth = ((borderSize*3)+(width*2))*scale
         @pngHeight = ((borderSize*3)+(height*2))*scale

      when 5
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [borderSize*scale, ((borderSize*3)+(height*2))*scale]
         @pngWidth = ((borderSize*3)+(width*2))*scale
         @pngHeight = ((borderSize*4)+(height*3))*scale

      when 6
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [borderSize*scale, ((borderSize*3)+(height*2))*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*3)+(height*2))*scale]
         @pngWidth = ((borderSize*3)+(width*2))*scale
         @pngHeight = ((borderSize*4)+(height*3))*scale

      when 7
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [borderSize*scale, ((borderSize*3)+(height*2))*scale]
         @pngWidth = ((borderSize*4)+(width*3))*scale
         @pngHeight = ((borderSize*4)+(height*3))*scale

      when 8
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [borderSize*scale, ((borderSize*3)+(height*2))*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*3)+(height*2))*scale]
         @pngWidth = ((borderSize*4)+(width*3))*scale
         @pngHeight = ((borderSize*4)+(height*3))*scale

      when 9
         @bmPositions << [borderSize*scale, borderSize*scale]
         @bmPositions << [((borderSize*2)+width)*scale, borderSize*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, borderSize*scale]
         @bmPositions << [borderSize*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, ((borderSize*2)+height)*scale]
         @bmPositions << [borderSize*scale, ((borderSize*3)+(height*2))*scale]
         @bmPositions << [((borderSize*2)+width)*scale, ((borderSize*3)+(height*2))*scale]
         @bmPositions << [((borderSize*3)+(width*2))*scale, ((borderSize*3)+(height*2))*scale]
         @pngWidth = ((borderSize*4)+(width*3))*scale
         @pngHeight = ((borderSize*4)+(height*3))*scale
      end
   end
   def bmPositions
    @bmPositions
   end
   def pngWidth
    @pngWidth
   end
   def pngHeight
    @pngHeight
   end
end
class SinglePNGFromNTCIP
   def initialize(w, h, bw, s, bmJson, outName, borderColor=:white, borderSize=5)
    @signWidth = w
    @signHeight = h
    @bitsPerPixel = bw
    @scale = s
    @outName = outName
    @parsedBitmaps  = JSON.parse(bmJson)
    @numBitmaps = @parsedBitmaps["bitmaps"].count

    #####
    # calculate positions of each page
    # in the encompassing image
    ###
    @panelDefs = PanelDefs.new(w, h, s, borderSize, @numBitmaps)

    if borderColor.instance_of? Array
       @borderColor = ChunkyPNG::Color::rgba(borderColor[0], borderColor[1], borderColor[2], 255)
    else
       @borderColor = borderColor
    end

      #####
      ## create the big png image
      ## all of the page images will be placed in this image
      #####
      @png = ChunkyPNG::Image.new(@panelDefs.pngWidth, @panelDefs.pngHeight, @borderColor)

      bppEnum =  ENUM_MonochromePixelWidth::ONE_BIT
      if 2 == @bitsPerPixel
         bppEnum =  ENUM_MonochromePixelWidth::TWO_BIT
      end
      @i2p = ImageToPng.new(@panelDefs.pngWidth, @panelDefs.pngHeight, bppEnum, @scale, nil, @outName)
         
   end
   ######
   # create images for each page 
   #####
   def toPNG
    #####
    # locate the bitmaps array
    # one bitmap for each page
    #####
    bitmapArrays = @parsedBitmaps["bitmaps"]

    #####
    # generate images for each page
    #####
    nPageIndex = 0
    bitmapArrays.each do |bm|
      ntcipArray = []
      bm.each do |sample|
        ntcipArray << sample
      end
      @i2p.to_png(@png, @signWidth, @signHeight, ntcipArray, @panelDefs.bmPositions[nPageIndex][0], @panelDefs.bmPositions[nPageIndex][1])
      nPageIndex = nPageIndex + 1
    end
   end
end

class SinglePNGFromPreview
   def initialize(w, h, s, bitmaps, outName, borderColor=:white, borderSize=5)
    @signWidth = w
    @signHeight = h
    @scale = s
    @outName = outName
    @bitmaps = bitmaps
    @numBitmaps = bitmaps.count

    #####
    # calculate positions of each page
    # in the encompassing image
    ###
    @panelDefs = PanelDefs.new(w, h, s, borderSize, @numBitmaps)

    if borderColor.instance_of? Array
       @borderColor = ChunkyPNG::Color::rgba(borderColor[0], borderColor[1], borderColor[2], 255)
    else
       @borderColor = borderColor
    end

      #####
      ## create the big png image
      ## all of the page images will be placed in this image
      #####
      @png = ChunkyPNG::Image.new(@panelDefs.pngWidth, @panelDefs.pngHeight, @borderColor)

      @i2p = PreviewImageToPng.new( @panelDefs.pngWidth, @panelDefs.pngHeight, @scale, nil, @outName)
         
   end
   ######
   # create images for each page 
   #####
   def toPNG
    #####
    # locate the bitmaps array
    # one bitmap for each page
    #####

    #####
    # generate images for each page
    #####
    nPageIndex = 0
    @bitmaps.each do |bm|
      @i2p.to_png(@png, @signWidth, @signHeight, bm, @panelDefs.bmPositions[nPageIndex][0], @panelDefs.bmPositions[nPageIndex][1])
      nPageIndex = nPageIndex + 1
    end
   end
end
#####
## generate NTCIP bitmap from text only page
## this class actually looks into the exported message page
#####
FC_DELIM_START = "\u00AB".encode('utf-8')
FC_DELIM_END = "\u00BB".encode('utf-8')

#########################################################################

class NTCIPFromTextPage
   def initialize(pageWidth, pageHeight, bitsPerPixel, thePage, fontList, fieldCodeList)
      @pageWidth = pageWidth
      @pageHeight = pageHeight
      @thePage = thePage
      @bitsPerPixel = bitsPerPixel
      @fontList = fontList
      @fieldCodeList = fieldCodeList
      @bitmap = []
      nBytes = (@bitsPerPixel*pageWidth*pageHeight)/8
      (0...nBytes).each do |b|
         @bitmap << 0
      end
   end
   def setBit(x, y, color)
      case @bitsPerPixel
       when 1
        byteIndex = x
        byteIndex += (y*@pageWidth)
        bitIndex = byteIndex
        byteIndex /= 8
        bitIndex = bitIndex - (byteIndex*8)
        if 0 < byteIndex
          if @bitmap.length > byteIndex
          @bitmap[byteIndex] |= 1<<(7-bitIndex)
          #puts "1-sb "+x.to_s+" "+y.to_s+" byteIndex "+byteIndex.to_s+" bitIndex "+bitIndex.to_s+" bm "+@bitmap[byteIndex].to_s(16)
          end
       end
       when 2
        byteIndex = (x*@bitsPerPixel)
        byteIndex += (y*@pageWidth*@bitsPerPixel)
        bitIndex = byteIndex
        byteIndex /= 8
        bitIndex = bitIndex - (byteIndex*8)
        if 0 < byteIndex
          if @bitmap.length > byteIndex
          bitsToSet = 0
          case color
            when CLASSIC_COLOR_AMBER

              bitsToSet = AMSIG_AMBER_PIXEL

            when CLASSIC_COLOR_RED

              bitsToSet = AMSIG_RED_PIXEL

            when CLASSIC_COLOR_WHITE

              bitsToSet = AMSIG_WHITE_PIXEL

            end
          end
          @bitmap[byteIndex] |= bitsToSet<<(6-bitIndex)
          #puts "2-sb "+x.to_s+" "+y.to_s+" byteIndex "+byteIndex.to_s+" bitIndex "+bitIndex.to_s+" bm "+@bitmap[byteIndex].to_s(16)
          end
       end
   end
   def locateFont(fontName)
      theFont = nil
      @fontList.each do |font|
       if font["name"] == fontName
         theFont = font
       end
      end
      theFont
   end
   def locateFontCharacter(theFont, c)
      theChar = nil
      theFont["characters"].each do |char|
        if c == char["encoding"]
         theChar = char
        end
      end
      theChar
   end
   def toBitmap
      #####
      ## for each of the 4 lines of text in this page
      ##
      ## grab the text string
      ##
      ## substitute any field codes
      ##
      ## locate the font
      ##
      ## calculate the starting location
      ##
      ## draw each character
      #####
      graphicObjectExport = @thePage["graphicObjectExport"]
      graphicObjectExport.each do |gObject|
      color = gObject["color"]
         xStart = gObject["xStart"]
         yStart = gObject["yStart"]
         text = gObject["text"]
         @fieldCodeList.list.each do |fc|
            text = text.gsub( FC_DELIM_START+fc.name+FC_DELIM_END, fc.value)
         end
         fontName = gObject["fontName"]
         theFont = locateFont(fontName)
         charSpacing = theFont["charspacing"]
         text.split("").each do |c|
            #####
            # get the font bits for this character
            # set each bit into the bitmap
            ######
            charBM = locateFontCharacter(theFont, c.ord)
            charWidth = charBM["width"]
            charHeight = charBM["height"]
            charBits = charBM["bitmap"]
            (charHeight-1).downto(0) do |y|
              bitTester = 0x80
              (0...charWidth).each do |x|
                if 0 != (charBits[y] & bitTester)
                  setBit(xStart+x, yStart+y, color)
                end
               bitTester >>= 1
              end
            end
            xStart = xStart+charWidth+charSpacing
         end
      end
   @bitmap
   end
end
