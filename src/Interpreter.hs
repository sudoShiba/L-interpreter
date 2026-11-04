module Interpreter where

import Types
import Data.Maybe
import Numeric.Natural (Natural, minusNaturalMaybe)

valOf :: Variable -> State -> Natural
valOf _ [] = 0
valOf v ((v' := val) : rest)
  | v == v'   = val
  | otherwise = valOf v rest

setVal :: Variable -> Natural -> State -> State
setVal v newVal [] = [v := newVal]
setVal v newVal ((v' := val) : rest)
  | v == v'   = (v := newVal) : rest
  | otherwise = (v' := val) : setVal v newVal rest

isTerminal :: Program -> Snapshot -> Bool
isTerminal prog (i, _) = i > fromIntegral (length prog)

findLabelIndex :: Label -> Program -> Natural
findLabelIndex targetLabel prog = search 1 prog
  where
    search _ [] = fromIntegral (length prog) + 1
    search idx (Labeled lbl _ : rest)
      | lbl == targetLabel = idx
      | otherwise          = search (idx + 1) rest
    search idx (Unlabeled _ : rest) = search (idx + 1) rest

successor :: Program -> Snapshot -> Maybe Snapshot
successor prog (i, sigma)
  | i < 1 || isTerminal prog (i, sigma) = Nothing
  | otherwise =
    let currentInst = prog !! fromIntegral (i - 1)
        statement = case currentInst of
          Unlabeled s -> s
          Labeled _ s -> s
    in Just (stepStatement statement)
  where
    stepStatement :: Statement -> Snapshot
    stepStatement (Inc v) = -- V <- V + 1
      let m = valOf v sigma
      in (i + 1, setVal v (m + 1) sigma)

    stepStatement (Dec v) = -- V <- V - 1
      let m = valOf v sigma
      in (i + 1, setVal v (fromMaybe 0 (minusNaturalMaybe m 1)) sigma)

    stepStatement (Noop _) = -- V <- V
      (i + 1, sigma)

    stepStatement (Goto v targetLabel) =
      let m = valOf v sigma
      in if m == 0
           then (i + 1, sigma) -- V = 0 -> increment pointer
           else (findLabelIndex targetLabel prog, sigma) -- V != 0 -> jump to targetLabel

initSnapshot :: [Natural] -> Snapshot
initSnapshot inputs =
  let inputEqs = zipWith (\idx val -> InputVar idx := val) [1..] inputs
      yEq      = [OutputVar := 0]
  in (1, yEq ++ inputEqs)

runTrace :: Natural -> Program -> Snapshot -> [Snapshot]
runTrace 0 _ current = [current]
runTrace maxSteps prog current =
  current : case successor prog current of
              Nothing   -> []
              Just next -> runTrace (maxSteps - 1) prog next

