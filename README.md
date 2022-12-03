# timesheet

A simple program for calculating how many hours I have worked today so far.

Here's an example input file:

    $ cat example-timesheet.txt
    Mon 2022-11-14
      9:00-9:45 Emails
      9:45-12:00 Implementing a timesheet program
      # lunch time
      13:15-16:00 Implementing a timesheet program
      16:00-17:30 Testing the timesheet program 

    Tue 2022-11-15
      8:45-9:45 Emails
      # short break
      10:00- Documenting the timesheet program

If I run `timesheet` at 10:00, then it will say that I have worked 1 hour today
so far, namely from 8:45 to 9:45. Since the last range is open, if I run
`timesheet` at 10:15, it will take that extra 15 minutes into account and say
that I have worked 1 hour and 15 minutes today so far.

    $ date +"%H:%M"
    10:16
    $ cabal run timesheet < example-timesheet.txt
    I have worked 1 hours and 15 minutes today so far.
