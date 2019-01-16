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
            nBits = (pageWidth)*pageWidth
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
                    @png[xOffset+nX+xs,yOffset+nY+ys] = ChunkyPNG::Color.rgba(nRed, nGreen, nBlue, 255)
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
            nBits = pageHeight*pageWidth
            nBytes = nBits/4
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
class SinglePNGFromNTCIP
   def initialize(w, h, bw, s, bmJson, outName, borderColor=:white, borderSize=5)
    @signWidth = w
    @signHeight = h
    @bitsPerPixel = bw
    @scale = s
    @outName = outName
    @parsedBitmaps  = JSON.parse(bmJson)
    @numBitmaps = @parsedBitmaps["bitmaps"].count
    @bmPositions = []
    @pngWidth = 0
    @pngHeight = 0

    if borderColor.instance_of? Array
       @borderColor = ChunkyPNG::Color::rgba(borderColor[0], borderColor[1], borderColor[2], 255)
    else
       @borderColor = borderColor
    end

    #####
    # calculate positions for each page 
    # in the encompassing image
    #####
    case @numBitmaps
      when 1
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @pngWidth = ((borderSize*2)+w)*@scale
         @pngHeight = ((borderSize*2)+h)*@scale

      when 2
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @pngWidth = ((borderSize*3)+(w*2))*@scale
         @pngHeight = ((borderSize*2)+h)*@scale

      when 3
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @pngWidth = ((borderSize*3)+(w*2))*@scale
         @pngHeight = ((borderSize*3)+(h*2))*@scale

      when 4
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*2)+h)*@scale]
         @pngWidth = ((borderSize*3)+(w*2))*@scale
         @pngHeight = ((borderSize*3)+(h*2))*@scale

      when 5
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*3)+(h*2))*@scale]
         @pngWidth = ((borderSize*3)+(w*2))*@scale
         @pngHeight = ((borderSize*4)+(h*3))*@scale
      when 6
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*3)+(h*2))*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*3)+(h*2))*@scale]
         @pngWidth = ((borderSize*3)+(w*2))*@scale
         @pngHeight = ((borderSize*4)+(h*3))*@scale
      when 7
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*3)+(h*2))*@scale]
         @pngWidth = ((borderSize*4)+(w*3))*@scale
         @pngHeight = ((borderSize*4)+(h*3))*@scale
      when 8
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*3)+(h*2))*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*3)+(h*2))*@scale]
         @pngWidth = ((borderSize*4)+(w*3))*@scale
         @pngHeight = ((borderSize*4)+(h*3))*@scale
      when 9
         @bmPositions << [borderSize*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, borderSize*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, borderSize*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, ((borderSize*2)+h)*@scale]
         @bmPositions << [borderSize*@scale, ((borderSize*3)+(h*2))*@scale]
         @bmPositions << [((borderSize*2)+w)*@scale, ((borderSize*3)+(h*2))*@scale]
         @bmPositions << [((borderSize*3)+(w*2))*@scale, ((borderSize*3)+(h*2))*@scale]
         @pngWidth = ((borderSize*4)+(w*3))*@scale
         @pngHeight = ((borderSize*4)+(h*3))*@scale
      end

      #####
      ## create the big png image
      ## all of the page images will be placed in this image
      #####
      @png = ChunkyPNG::Image.new(@pngWidth, @pngHeight, @borderColor)

      bppEnum =  ENUM_MonochromePixelWidth::ONE_BIT
      if 2 == @bitsPerPixel
         bppEnum =  ENUM_MonochromePixelWidth::TWO_BIT
      end
      @i2p = ImageToPng.new(@pngWidth, @pngHeight, bppEnum, @scale, nil, @outName)
         
   end
   ######
   # create images for each page 
   #####
   def toPNG()
    #####
    # locate the bitmaps array
    # one bitmap for each page
    #####
    graphicType = @parsedBitmaps["graphicType"]
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
      @i2p.to_png(@png, @signWidth, @signHeight, ntcipArray, @bmPositions[nPageIndex][0], @bmPositions[nPageIndex][1])
      nPageIndex = nPageIndex + 1
    end
   end
end
