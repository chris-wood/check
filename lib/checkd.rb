require 'git'
require 'logger'
require 'digest'
require 'yaml'
require 'json'
require 'pathname'
require 'filewatcher'
require 'net/https'

DEFAULT_FNAME_MASTER = ".check_master"
DEFAULT_FNAME = ".check"

class CheckpointMaster

    attr_reader :repo_list

    def initialize(fname)
        abs_path = File.join(Dir.home, fname)
        if not File.exists?(abs_path) then
            @repos = []
            File.new(abs_path, File::CREAT|File::TRUNC|File::RDWR, 0644)
            File.open(abs_path, 'w+') {|f| f.write(YAML::dump(@repos)) }
        else
            file_data = File.read(abs_path)
            @repos = YAML::load(file_data)
        end

        @repo_list = []
        @repos.each do |repo|
            @repo_list << Repository.new(repo["path"])
        end
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
            repo = Repository.new(File.absolute_path(path))
            @repo_list << repo
            @repos << {"path" => abs_path, "digest" => repo.get_repo_digest()}
        else
            raise "Not a valid Git repository"
        end
    end

    def dump()
        # Write the repo list to disk
        puts YAML::dump(@repos)
    end
end

# Process.daemon(true)

master = CheckpointMaster.new(DEFAULT_FNAME_MASTER)
thread = master.add_repo("..")
puts master.repo_list
puts master.dump()

# Run forever until told to stop
puts "Starting daemon"
repo_index = 0
loop do
    # pid = Process.fork do
    # end
    # Process.waitpid(pid)

    repo = master.repo_list[repo_index]
    if repo.has_changed() then
        puts "CHANGED!"
        repo.dump()
    else
        puts "static....."
    end

    sleep(1)
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
