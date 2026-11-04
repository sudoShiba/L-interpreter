module Parser where

import Types
import Numeric.Natural (Natural)
import Data.Void (Void)
import Data.Maybe (fromMaybe)
import Control.Applicative (empty)
import Text.Megaparsec hiding (Label)
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void String

sc :: Parser ()
sc = L.space space1 empty empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

parseVar :: Parser Variable
parseVar = lexeme $ do
  firstChar <- upperChar
  case firstChar of
    'Y' -> return OutputVar
    'X' -> do
      num <- optional L.decimal
      return $ InputVar (fromMaybe 1 num)
    'Z' -> do
      num <- optional L.decimal
      return $ LocalVar (fromMaybe 1 num)
    _   -> fail "Invalid variable (expects Y, X or Z)"

parseLabelLetter :: Parser LabelLetter
parseLabelLetter = choice
  [ A <$ char 'A'
  , B <$ char 'B'
  , C <$ char 'C'
  , D <$ char 'D'
  , E <$ char 'E'
  ]

parseLabel :: Parser Label
parseLabel = lexeme $ do
  grp <- parseLabelLetter
  num <- optional L.decimal
  return (Label grp (fromMaybe 1 num))

parseStatement :: Parser Statement
parseStatement = lexeme $ try parseIfGoto <|> parseAssignment
  where
    parseIfGoto = do
      _ <- string "IF"
      sc
      v <- parseVar
      sc
      _ <- string "!="
      sc
      _ <- char '0'
      sc
      _ <- string "GOTO"
      sc
      lbl <- parseLabel
      return (Goto v lbl)

    parseAssignment = do
      v <- parseVar
      sc
      _ <- string "<-"
      sc
      try (parseArithmetic v) <|> parseNoop v

    parseNoop v = do
      v2 <- parseVar
      if v == v2
        then return (Noop v)
        else fail "Invalid assignment"

    parseArithmetic v = do
      v2 <- parseVar
      if v /= v2
        then fail "Variable does not match"
        else return ()
      sc
      op <- char '+' <|> char '-'
      sc
      _ <- char '1'
      case op of
        '+' -> return (Inc v)
        '-' -> return (Dec v)
        _   -> fail "Expects +1 or -1"

parseInstruction :: Parser Instruction
parseInstruction = lexeme $ do
  lbl <- optional (try (lexeme (between (char '[') (char ']') (sc *> parseLabel <* sc))))
  stmt <- parseStatement
  return $ case lbl of
    Nothing -> Unlabeled stmt
    Just l  -> Labeled l stmt

parseProgram :: Parser Program
parseProgram = between sc eof (many parseInstruction)

