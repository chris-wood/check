class Commit
    attr_accessor :stats # hash as below
    # {:total=>{:insertions=>0, :deletions=>13, :lines=>13, :files=>1},
    # :files=>{"src/gitones.rb"=>{:insertions=>0, :deletions=>13}}}

    def initialize(entry, stats)
        @entry = entry
        @stats = stats
    end

    def message
        @entry.message
    end

    def author
        @entry.author
    end

    def date
        @entry.date
    end

    def additions
        @stats[:total][:insertions]
    end

    def deletions
        @stats[:total][:deletions]
    end

    def numberOfLinesChanged
        @stats[:total][:lines]
    end

    def numberOfFilesTouched
        @stats[:total][:files]
    end
end
