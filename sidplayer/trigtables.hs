import Data.List
import System.Environment
import System.IO (stderr, hPutStrLn)

degToRad :: Floating a => a -> a
degToRad deg = deg * pi / 180

genTrigTables :: Int -> Int -> (Double, Double) -> ([Int], [Int])
genTrigTables radius steps (fromAngle, toAngle) = (cosTable, sinTable)
    where
        stepAngle = (toAngle - fromAngle) / ((fromIntegral steps) -1)
        angles = [fromAngle + stepAngle * fromIntegral step | step <- [0 .. steps - 1]]
        sinTable = map (round . (* fromIntegral radius) . sin) angles
        cosTable = map (round . (* fromIntegral radius) . cos) angles

printAcmeLookupTable :: String -> [Int] -> IO ()
printAcmeLookupTable label table = do
    putStrLn (label ++ ":")
    putStrLn ("!byte " ++ intercalate "," (map show table))

main :: IO ()
main = do
    args <- getArgs
    if length args < 6
        then hPutStrLn stderr "Not enough arguments! Usage: program radius steps fromAngle toAngle"
        else do
            let
                xHeader = head args
                yHeader = args !! 1
                radius = read (args !! 2) :: Int
                steps = read (args !! 3) :: Int
                fromAngleDegrees = read (args !! 4) :: Double
                toAngleDegrees = read (args !! 5) :: Double
                fromAngle = degToRad fromAngleDegrees
                toAngle = degToRad toAngleDegrees
                (xTable, yTable) = genTrigTables radius steps (fromAngle, toAngle)
            printAcmeLookupTable xHeader xTable
            printAcmeLookupTable yHeader yTable