# timesheet

A simple program for calculating how many hours I have worked today so far.

Here's an example input file:

    $ cat example-timesheet.txt
    Mon 2022-11-14
      9:00-9:45 Emails
      9:45-12:00 Implementing a timesheet program
      # lunch time
      13:15-16:00 Implementing a timesheet program
      16:00-17:15 Testing the timesheet program
      # I worked 7:00 today, missing 1h00, missing 1h00 in total

    Tue 2022-11-15 (holiday)
      9:00-9:30 Emails
      # I worked 0:30 today, missing 0h00, missing 0h30 in total

    Wed 2022-11-16
      8:45-9:45 Emails
      # short break
      10:00- Documenting the timesheet program

Let's look at Wednesday first. If I run `timesheet` at 10:00, then it will say
that I have worked 1h00 today so far, namely from 8:45 to 9:45. Since the last
time range is open, if I run `timesheet` at 11:00, it will take that extra hour
into account and say that I have worked 2h00 today so far. All times are
rounded to 0h15 increments.

    $ date +"%H:%M"
    11:03
    $ cabal run timesheet < example-timesheet.txt
    I worked 2h00 today, missing 6h00, missing 6h30 in total

I aim to work 8 hours a day, so timesheet is also telling me how much time
remains in order to accomplish that goal. Sometimes I go over or under that
goal, in which case I track the discrepancy over time, so the 1h00 I was
missing on Monday carries over on Tuesday.
