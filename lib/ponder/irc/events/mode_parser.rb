module Ponder
  module IRC
    module Events
      module ModeParser
        def parse(modes, params, isupport)
          modes = modes.split(//)
          direction = modes.shift.to_sym
          unless [:'+', :'-'].include?(direction)
            raise(ArgumentError, "Direction for modes argument not given. +/- needed, got: #{direction}.")
          end
          params = params.split(/ /)
          mode_changes = []

          modes.each do |mode|
            if needs_a_param?(mode, direction, isupport)
              param = params.shift

              if param
                mode_change = {
                  :direction => direction,
                  :mode => mode,
                  :param => param
                }
                mode_changes << mode_change
              end
            else
              mode_change = {
                :direction => direction,
                :mode => mode
              }
              mode_changes << mode_change
            end
          end

          mode_changes
        end
        module_function :parse

        def needs_a_param?(mode, direction, isupport)
          modes = isupport['CHANMODES']['A'] +
            isupport['CHANMODES']['B'] +
            isupport['PREFIX'].keys
          modes.concat(isupport['CHANMODES']['C']) if direction == :'+'
          modes.include?(mode)
        end
        module_function :needs_a_param?
      end
    end
  end
end
