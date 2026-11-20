# :stopdoc:
require "rake"

module Rake
  class Application
    attr_accessor :start_time
  end

  class Task
    alias _original_invoke invoke

    def invoke(*)
      enhance do
        puts "Total execution time #{Time.now - Rake.application.start_time}" if Rake.application.start_time
      end
      _original_invoke(*)
    end
  end
end

# :startdoc:
