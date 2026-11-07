{-# LANGUAGE ForeignFunctionInterface #-}
module Main where

import Data.Char (isDigit)
import Foreign.C.String (CString, newCString, peekCString)
import Numeric.Natural (Natural)
import Text.Megaparsec (runParser, errorBundlePretty)

import Parser (parseProgram)
import Interpreter (initSnapshot, runTrace)

foreign export ccall runTraceWasm :: CString -> Int -> CString -> IO CString

-- Inputs arrive as text ("3, 5") so they aren't limited to a 32-bit Int.
parseInputs :: String -> Maybe [Natural]
parseInputs = traverse parseOne . words . map commaToSpace
  where
    commaToSpace c = if c == ',' then ' ' else c
    parseOne s
      | all isDigit s = Just (read s)
      | otherwise     = Nothing

runTraceWasm :: CString -> Int -> CString -> IO CString
runTraceWasm cCode maxSteps cInputs = do
  codeStr <- peekCString cCode
  inputsStr <- peekCString cInputs
  case (parseInputs inputsStr, runParser parseProgram "" codeStr) of
    (Nothing, _) -> newCString "INPUT ERROR:\nInputs must be natural numbers separated by commas, for example: 3, 5"
    (_, Left err) -> newCString ("PARSE ERROR:\n" ++ errorBundlePretty err)
    (Just inputs, Right prog) -> do
      let start = initSnapshot prog inputs
          trace = runTrace (fromIntegral (max 0 maxSteps)) prog start
      newCString (unlines (map show trace))

main :: IO ()
main = return ()

