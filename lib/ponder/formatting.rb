module Ponder
  module Formatting
    PLAIN        = 15.chr
    BOLD         = 2.chr
    ITALIC       = 22.chr
    UNDERLINE    = 31.chr
    COLOR_CODE   = 3.chr
    UNCOLOR_CODE = COLOR_CODE
    
    #mIRC color codes from http://www.mirc.com/help/colors.html
    COLORS = {
      :white  => '00',
      :black  => '01',
      :blue   => '02',
      :green  => '03',
      :red    => '04',
      :brown  => '05',
      :purple => '06',
      :orange => '07',
      :yellow => '08',
      :lime   => '09',
      :teal   => '10',
      :cyan   => '11',
      :royal  => '12',
      :pink   => '13',
      :gray   => '14',
      :silver => '15'
    }
  end
end

