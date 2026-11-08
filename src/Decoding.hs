module Decoding where

import Types
import Data.Bits ((.&.), xor, shiftR)
import Data.Numbers.Primes (primes, primeFactors)
import GHC.Num.Natural (naturalLog2)
import Numeric.Natural (Natural)

-- with <x,y> = 2^x * (2*y + 1) - 1
-- l(z) = x, r(z) = y
l :: Natural -> Natural
l = fst . unpair

r :: Natural -> Natural
r = snd . unpair

unpair :: Natural -> (Natural, Natural)
unpair z = (x, (n `shiftR` fromIntegral x - 1) `div` 2)
  where
    n = z + 1
    x = fromIntegral (naturalLog2 (n .&. (n `xor` (n - 1))))

exponents :: Natural -> [Natural]
exponents 1 = []
exponents n = [count p | p <- takeWhile (<= maximum fs) primes]
  where
    fs = primeFactors n
    count p = fromIntegral (length (filter (== p) fs))

decodeProgram :: Natural -> Program
decodeProgram n = map decodeInstruction (exponents (n + 1))

decodeInstruction :: Natural -> Instruction
decodeInstruction z = case a of
  0 -> Unlabeled stmt
  _ -> Labeled (decodeLabel a) stmt
  where
    (a, rest) = unpair z
    (b, c)    = unpair rest
    v         = decodeVar (c + 1)
    stmt = case b of
      0 -> Noop v
      1 -> Inc v
      2 -> Dec v
      _ -> Goto v (decodeLabel (b - 2))

decodeLabel :: Natural -> Label
decodeLabel k = Label letter ((k - 1) `div` 5 + 1)
  where
    letter = [A, B, C, D, E] !! fromIntegral ((k - 1) `mod` 5)

decodeVar :: Natural -> Variable
decodeVar k
  | k == 1    = OutputVar
  | even k    = InputVar (k `div` 2)
  | otherwise = LocalVar ((k-1) `div` 2)

