require 'thor'

# monkey patch preventing Thor from screwing formatting in our commands' long_desc
# credits: https://github.com/erikhuda/thor/issues/398#issuecomment-237400762
class Thor
  module Shell
    class Basic
      def print_wrapped(message, options = {})
         stdout.puts message
       end
    end
  end
end

module CalendariumRomanum

  # Implementation of the +calendariumrom+ executable.
  # _Not_ loaded by default when you +require+ the gem.
  #
  # @api private
  class CLI < Thor
    desc 'query [DATE]', 'show calendar information for a specified date/month/year'
    long_desc <<-EOS
show calendar information for a specified date/month/year

DATE formats:
not specified - today
2000-01-02    - single date
2000-01       - month
2000          - year
EOS
    option :calendar, default: 'universal-en', aliases: :c, desc: 'sanctorale data file to use'
    option :locale, default: 'en', aliases: :l, desc: 'locale to use for localized strings'
    def query(date_str = nil)
      Querier
        .new(locale: options[:locale], calendar: options[:calendar])
        .call(date_str)
    end

    desc 'calendars', 'list calendars available for querying'
    def calendars
      Data.each {|c| puts c.siglum }
    end

    desc 'errors FILE1, ...', 'find errors in sanctorale data files'
    def errors(*files)
      files.each do |path|
        begin
          sanctorale_from_path path
        rescue Errno::ENOENT, InvalidDataError => err
          die! err.message
        end
      end
    end

    desc 'cmp FILE1, FILE2', 'detect differences between two sanctorale data files'
    def cmp(a, b)
      Comparator.new.call(a, b)
    end

    desc 'dump YEAR', 'print calendar of the specified year for use in regression tests'
    def dump(year)
      Dumper.new.regression_tests_dump year.to_i
    end

    desc 'version', 'print version information'
    def version
      puts 'calendarium-romanum CLI'
      puts "calendarium-romanum: version #{CalendariumRomanum::VERSION}, released #{CalendariumRomanum::RELEASE_DATE}"
    end
  end
end

# required files reopen the CLI class - require after the class'es main definition
# in order to prevent superclass mismatch errors
require_relative 'cli/helper'

CalendariumRomanum::CLI.include CalendariumRomanum::CLI::Helper

require_relative 'cli/dumper'
require_relative 'cli/comparator'
require_relative 'cli/querier'
