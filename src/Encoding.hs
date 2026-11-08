module Encoding where

import Types
import Data.Numbers.Primes (primes)
import Numeric.Natural (Natural)

godelNumber :: [Natural] -> Natural
godelNumber nums = product $ zipWith (^) primes nums

pair :: Natural -> Natural -> Natural
pair x y = 2^x * (2*y + 1) - 1 -- this subtraction always has a positive result

-- #(V): Y X1 Z1 X2 Z2 X3 ...
encodeVar :: Variable -> Natural
encodeVar OutputVar    = 1
encodeVar (InputVar i) = 2 * i
encodeVar (LocalVar i) = 2 * i + 1

-- #(L): A1 B1 C1 D1 E1 A2 ...
encodeLabel :: Label -> Natural
encodeLabel (Label letter k) = 5 * (k - 1) + encodeLetter letter

encodeLetter :: LabelLetter -> Natural
encodeLetter A = 1
encodeLetter B = 2
encodeLetter C = 3
encodeLetter D = 4
encodeLetter E = 5

encodeInstruction :: Instruction -> Natural
encodeInstruction instr = pair a (pair (statementCode s) (encodeVar (statementVar s) - 1))
  where
    (a, s) = case instr of
      Unlabeled st  -> (0, st)
      Labeled l st  -> (encodeLabel l, st)

statementCode :: Statement -> Natural
statementCode (Noop _)   = 0
statementCode (Inc _)    = 1
statementCode (Dec _)    = 2
statementCode (Goto _ l) = encodeLabel l + 2

statementVar :: Statement -> Variable
statementVar (Noop v)   = v
statementVar (Inc v)    = v
statementVar (Dec v)    = v
statementVar (Goto v _) = v

encodeProgram :: Program -> Natural
encodeProgram p = godelNumber (map encodeInstruction p) - 1

