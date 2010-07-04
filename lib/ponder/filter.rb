require 'ponder/callback'

module Ponder
  class Filter < Callback
    LISTENED_TYPES += [:all]
  end
end
