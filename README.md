# check
check is a program to help manage time and activity for git-based projects.    

# Workflow

(Optional) Step 1: Start the daemon to monitor repositories
```
$ ruby checkd.rb &
```

Step 2: Use the check tool
```
$ check -s # start a check point
...
$ check -e # end a check point and log it
```

Step 3: Work, work, work.

Step 4: Query the check points for information about past work
```
$ check --stats --all
<display stats for all repos>
$ check --logs --all
<display logs for all repos (sorted by time)
$ check --todos 
<display TODOs for this repository>
```

# Dependencies

- todo.txt CLI (https://github.com/ginatrapani/todo.txt-cli/releases)
- git_status ruby gem (https://github.com/tomgi/git_stats)
- sparkr (gem install sparkr) (http://trivelop.de/sparkr/)
    - Sparkr.sparkline([0,1,2,3,4,5] * 100)
- ascii_charts (https://github.com/benlund/ascii_charts) (gem install ascii_charts)

# Stats

Sparkline generation

Check reports the following stats for your measurement

- Total commits today
- Changes today (files touched and changes in each)
- Commits over last 7 days
- Changes over last 7 days (ditto)
- Current commit streak
- Development velocity (changes over time)
- Time spent per branch (thrashing)
- Time between commits
- Identify roadblocks (files continue to work on)
- Integration with GitStats (https://github.com/tomgi/git_stats) -> for pretty and comprehensive git stat generation

# Configuration

You need to set up a shell alias to capture your git workflow. 

TODO: update this
```
git-checkpoint() {
    check -l "$1"
    $1 
}
alias git=git-checkpoint
```

# Internals

Check is designed to work by recording "checkpoint" events and logging all
user activity in between checkpoints. These events are collected into a 
checkpoint file that is commited into the repository along with the 
repository. The development activity lives alongside the code. 

Checkpoint files are simple logs of all checkpoint and user activity.
They are structured according to the following schema.

```
Event        := CheckEvent | GitEvent
CheckEvent   := CheckCommand Time RepoState
Time         := Timestamp (ms)
RepoState    := RepoHashDigest RepoBranch
CheckCommand := Start | Stop
GitEvent     := GitCommand (more...)
GitCommand   := <log of git command>
```

