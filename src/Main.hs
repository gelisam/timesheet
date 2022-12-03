{-# LANGUAGE GeneralizedNewtypeDeriving, NamedFieldPuns, ViewPatterns #-}
module Main where

import Control.Category ((>>>))
import Data.Maybe (fromMaybe)
import Data.Time (DiffTime, LocalTime(LocalTime), TimeOfDay(TimeOfDay))
import Text.Read (readMaybe)
import qualified Data.Time as Time
import qualified Data.Time.Calendar.OrdinalDate as Time


data Day = Day
  { date
      :: String
  , lineItems
      :: [LineItem]
  }
  deriving Show

data LineItem = LineItem
  { startTime
      :: TimeOfDay
  , stopTime
      :: Maybe TimeOfDay
  , description
      :: String
  }
  deriving Show

stripComments
  :: [String]
  -> [String]
stripComments
  = filter (not . startsWithHash)
  where
    startsWithHash
      :: String
      -> Bool
    startsWithHash ('#':_)
      = True
    startsWithHash _
      = False

parseDay
  :: [String]
  -> Day
parseDay
  ( date_
  : ( fmap unindent
  >>> stripComments
  >>> fmap parseLineItem
   -> lineItems_
    )
  )
  = Day date_ lineItems_
parseDay ss
  = error $ "missing date header in "
         ++ show ss

unindent
  :: String
  -> String
unindent (' ':' ':s)
  = s
unindent s
  = error $ "missing indentation in "
         ++ show s

parseLineItem
  :: String
  -> LineItem
parseLineItem
  ( ( break (== '-')
   -> ( parseTimestamp -> startTime_
      , '-'
      : ( break (== ' ')
       -> ( parseMaybeTimestamp -> stopTime_
          , ' ':description_
          )
        )
      )
    )
  )
  = LineItem startTime_ stopTime_ description_

parseMaybeTimestamp
  :: String
  -> Maybe TimeOfDay
parseMaybeTimestamp ""
  = Nothing
parseMaybeTimestamp s
  = Just (parseTimestamp s)

parseTimestamp
  :: String
  -> TimeOfDay
parseTimestamp
  ( break (== ':')
 -> ( ( parseInt
     -> hours
      )
    , ':'
    : ( parseInt
     -> minutes
      )
    )
  )
  = TimeOfDay hours minutes 0
parseTimestamp s
  = error $ "not a timestamp: "
         ++ show s

parseInt
  :: String
  -> Int
parseInt s
  = case readMaybe s of
      Just n
        -> n
      Nothing
        -> error $ "not an integer: "
                ++ show s

parseDays
  :: [String]
  -> [Day]
parseDays = fmap parseDay . filter (not . null) . go []
  where
    go
      :: [String]
      -> [String]
      -> [[String]]
    go currentDay (s@(' ':_) : ss)
      = go (currentDay ++ [s]) ss
    go currentDay (s:ss)
      = currentDay
      : go [s] ss
    go currentDay []
      = [currentDay]


lineItemDuration
  :: TimeOfDay
  -> LineItem
  -> DiffTime
lineItemDuration now (LineItem {startTime, stopTime})
    = Time.timeOfDayToTime (fromMaybe now stopTime)
    - Time.timeOfDayToTime startTime

-- doesn't matter which day, as long as everything is on the same day
timeOfDay_to_localTime
  :: TimeOfDay
  -> LocalTime
timeOfDay_to_localTime
  = LocalTime (Time.fromOrdinalDate 1970 0)


minutesToDiffTime
  :: Integer
  -> DiffTime
minutesToDiffTime minutes
  = Time.secondsToDiffTime (minutes * 60)

roundToNearestFifteenMinutes
  :: DiffTime
  -> DiffTime
roundToNearestFifteenMinutes diffTime
  = let diffToPico :: DiffTime -> Rational
        diffToPico = fromIntegral . Time.diffTimeToPicoseconds
        
        picoToDiff :: Rational -> DiffTime
        picoToDiff = Time.picosecondsToDiffTime . round
        
        roundRational :: Rational -> Rational
        roundRational = fromInteger . round

        fifteenMinutes :: Rational
        fifteenMinutes = diffToPico $ minutesToDiffTime 15
 in picoToDiff
      ( roundRational (diffToPico diffTime / fifteenMinutes)
      * fifteenMinutes
      )

timeWorkedToday
  :: TimeOfDay
  -> String
  -> String
timeWorkedToday now
    = lines
  >>> stripComments
  >>> parseDays
  >>> last
  >>> lineItems
  >>> map (lineItemDuration now)
  >>> sum
  >>> roundToNearestFifteenMinutes
  >>> Time.timeToTimeOfDay
  >>> ( \(TimeOfDay hours minutes _)
     -> "I worked "
     ++ show hours
     ++ "h"
     ++ show minutes
     ++ " today\n"
      )


getCurrentTimeOfDay
  :: IO TimeOfDay
getCurrentTimeOfDay = do
  now <- Time.getCurrentTime
  timeZone <- Time.getCurrentTimeZone
  pure $ Time.localTimeOfDay $ Time.zonedTimeToLocalTime $ Time.utcToZonedTime timeZone now

test
  :: IO ()
test = do
  now <- getCurrentTimeOfDay
  s <- readFile "example-timesheet.txt"
  putStr $ timeWorkedToday now s

main
  :: IO ()
main = do
  now <- getCurrentTimeOfDay
  interact (timeWorkedToday now)
