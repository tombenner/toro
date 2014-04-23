module Toro
  module Monitor
    class TimeFormatter
      class << self
        include ActionView::Helpers::DateHelper

        def distance_of_time(from_time, to_time)
          replacements = {
            'less than ' => '',
            'about ' => '',
            ' days' => 'd',
            ' day' => 'd',
            ' hours' => 'h',
            ' hour' => 'h',
            ' minutes' => 'm',
            ' minute' => 'm',
            ' seconds' => 's',
            ' second' => 's'
          }
          phrase = distance_of_time_in_words(from_time, to_time, include_seconds: true)
          replacements.each { |from, to| phrase.gsub!(from, to) }
          phrase
        end
      end
    end
  end
end
