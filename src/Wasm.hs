{-# LANGUAGE ForeignFunctionInterface #-}
module Main where

import Data.Char (isDigit)
import Foreign.C.String (CString, newCString, peekCString)
import Numeric.Natural (Natural)
import Text.Megaparsec (runParser, errorBundlePretty)

import Parser (parseProgram)
import Interpreter (initSnapshot, runTrace)
import Encoding (encodeProgram)
import Decoding (decodeProgram)
import Printer (showProgram)

foreign export ccall runTraceWasm :: CString -> Int -> CString -> IO CString
foreign export ccall encodeProgramWasm :: CString -> IO CString
foreign export ccall decodeProgramWasm :: CString -> IO CString

-- Numbers arrive as text so they aren't limited to a 32-bit Int.
parseNatural :: String -> Maybe Natural
parseNatural s
  | not (null s) && all isDigit s = Just (read s)
  | otherwise                     = Nothing

parseInputs :: String -> Maybe [Natural]
parseInputs = traverse parseNatural . words . map commaToSpace
  where
    commaToSpace c = if c == ',' then ' ' else c

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

-- Program text -> #(P)
encodeProgramWasm :: CString -> IO CString
encodeProgramWasm cCode = do
  codeStr <- peekCString cCode
  case runParser parseProgram "" codeStr of
    Left err   -> newCString ("PARSE ERROR:\n" ++ errorBundlePretty err)
    Right prog -> newCString (show (encodeProgram prog))

-- #(P) -> program text
decodeProgramWasm :: CString -> IO CString
decodeProgramWasm cNumber = do
  numberStr <- peekCString cNumber
  case words numberStr of
    [w] | Just n <- parseNatural w -> newCString (showProgram (decodeProgram n))
    _ -> newCString "INPUT ERROR:\nA program number must be a single natural number, for example: 189"

main :: IO ()
main = return ()
