require 'git'
require 'json'
require 'logger'
require 'digest'
require 'yaml'
require 'pathname'
require 'filewatcher'
require 'net/https'

DEFAULT_FNAME = ".check"

class CheckpointMaster
    def initialize(fname)
        abs_path = File.join(Dir.home, fname)
        if not File.exists?(abs_path) then
            File.new(abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
            File.open(abs_path, 'w+') {|f| f.write(JSON.generate({})) }
        end

        # Load and parse the JSON file
        file_data = File.read(abs_path)
        @data = JSON.parse(file_data)

        # Build up the repo list
        @repo_list = []
        if not @data.has_key?("repos") then
            @data["repos"] = {}
        else
            @data["repos"].each do |repo|
                @repo_list << Repository.new(repo["path"])
            end
        end
    end

    def repos()
        @repo_list
    end

    def add_repo(path)
        abs_path = File.absolute_path(path)
        repo = false
        Dir.entries(abs_path).each {|entry|
            if File.directory?(File.join(abs_path,entry)) and entry == ".git" then
                repo = true
            end
        }
        if repo then
            @repo_list << Repository.new(File.absolute_path(path))
        else
            raise "Not a valid Git repository"
        end
    end

    def dump()
        # Write the repo list to disk
    end
end

class Repository
    attr_accessor :path
    attr_accessor :thread
    attr_accessor :old_digest
    attr_accessor :repo_data

    def initialize(path)
        @path = path

        puts "Initializing repo at", path

        abs_path = File.join(path, ".check")
        if not File.exists?(abs_path) then
            File.new(abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)

            @repo_data = {}
            @repo_data[:digest] = self.get_repo_digest()
            File.open(abs_path, 'w') {|f| f.write @repo_data.to_yaml }

            puts "created"
        else
            @repo_data = YAML::load_file(abs_path)
            puts "loaded"
        end

        puts repo_data.to_s
    end

    def get_repo_digest()
        files = Dir["#{path}/.git/**/*"].reject{|f| File.directory?(f)}
        content = files.select{|f| f != ".check"}.map{|f| File.read(f)}.join
        return Digest::SHA256.digest(content).to_s
    end

    def has_changed()
        digest = self.get_repo_digest()
        puts digest, @repo_data[:digest]
        return digest != @repo_data[:digest]
    end

    def dump()
        # Update the master and invoke dump on the master
    end
end

class Checkpoint
    def initialize(repo_path)

    end

    def start()

    end

    def end()

    end
end

class Commit
    attr_accessor :sentiment # double
    attr_accessor :political # hash

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

# Process.daemon(true)

master = CheckpointMaster.new(DEFAULT_FNAME)
thread = master.add_repo("..")

# Run forever until told to stop
puts "Starting daemon"
repo_index = 0
loop do
    pid = Process.fork do
        repo = master.repos[repo_index]
        if repo.has_changed() then
            puts "something changed here!"
        end
    end

    Process.waitpid(pid)

    sleep(0.1)
end

# ARGV.each{|repo|
#     fullpath = Pathname.new(repo)
#     puts "Analyzing #{fullpath.realpath.to_s}"
#
#     # git = Git.open(repo, :log => Logger.new(STDOUT))
#     git = Git.open(repo)
#
#     # Indexes by user, date, and file
#     entriesByUser = {}
#     entriesByDate = {}
#     entriesByFile = {}
#
#     numEntries = git.log.size
#     for index in 0..(numEntries - 1)
#         entry = git.log[index]
#
#         user = entry.author.name
#         date = entry.date.strftime("%-m-%-d-%Y") # - means no padding
#         diff = git.diff(entry, git.log[index + 1])
#         diffStats = diff.stats
#         touchedFiles = diffStats[:files]
#
#         commit = Commit.new(entry, diffStats)
#         # puts commit.message
#         # puts commit.sentiment
#         # puts commit.political
#
#         if entriesByUser[user] == nil
#             entriesByUser[user] = []
#         end
#         entriesByUser[user] << commit
#
#         if entriesByDate[date] == nil
#             entriesByDate[date] = []
#         end
#         entriesByDate[date] << commit
#
#         touchedFiles.each{|fileName, value|
#             if entriesByFile[fileName] == nil
#                 entriesByFile[fileName] = []
#             end
#             entriesByFile[fileName] << commit
#         }
#     end
#
#     # puts "Indexes..."
#     # puts entriesByUser.to_s
#     # puts entriesByDate.to_s
#     # puts entriesByFile.to_s
#
#     # prepare the overall plot data
#     fout = File.open("overall.csv", "w")
#     entriesByDate.each{|data, commits|
#         add = commits[0].stats[:total][:insertions]
#         del = commits[0].stats[:total][:deletions]
#         lines = commits[0].stats[:total][:lines]
#         files = commits[0].stats[:total][:files]
#         sentiment = commits[0].sentiment
#         lib = commits[0].howLibertarian
#
#         csvcontents = [date.to_s, add, del, lines, files, sentiment, lib]
#         csvline = csvcontents.join(",")
#
#         puts date
#         fout.puts(csvline)
#     }
#     fout.close
#
#     # prepare the per-file plot data
#     entriesByFile.each{|file, commits|
#
#         # TODO: canonical the file
#
#         fout = File.open(file.sub("/", "_").to_s + ".csv", "w")
#
#         commits.each{|commit|
#             add = commit.stats[:total][:insertions]
#             del = commit.stats[:total][:deletions]
#             lines = commit.stats[:total][:lines]
#             files = commit.stats[:total][:files]
#             sentiment = commit.sentiment
#             lib = commit.howLibertarian
#
#             csvcontents = [date.to_s, add, del, lines, files, sentiment, lib]
#             csvline = csvcontents.join(",")
#
#             puts date
#             fout.puts(csvline)
#         }
#
#         fout.close
#     }
#
#     # prepare the per-user plot data
#     entriesByFile.each{|user, commits|
#         fout = File.open(user.sub("/", "_").to_s + ".csv", "w")
#
#         commits.each{|commit|
#             add = commit.stats[:total][:insertions]
#             del = commit.stats[:total][:deletions]
#             lines = commit.stats[:total][:lines]
#             files = commit.stats[:total][:files]
#             sentiment = commit.sentiment
#             lib = commit.howLibertarian
#
#             csvcontents = [date.to_s, add, del, lines, files, sentiment, lib]
#             csvline = csvcontents.join(",")
#
#             puts date
#             fout.puts(csvline)
#         }
#
#         fout.close
#     }
# }
