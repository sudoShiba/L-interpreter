module Printer where

import Types

-- Prints a program in the same syntax the parser reads, so a decoded
-- program can go straight back into the editor.
showProgram :: Program -> String
showProgram prog = unlines (map showInstruction prog)
  where
    width = maximum (0 : map (length . labelPrefix) prog)
    showInstruction instr = pad (labelPrefix instr) ++ showStatement (statementOf instr)
    pad s = s ++ replicate (width - length s) ' '

    labelPrefix (Labeled lbl _) = "[" ++ showLabel lbl ++ "] "
    labelPrefix (Unlabeled _)   = ""

    statementOf (Labeled _ s) = s
    statementOf (Unlabeled s) = s

showStatement :: Statement -> String
showStatement (Inc v)      = showVar v ++ " <- " ++ showVar v ++ " + 1"
showStatement (Dec v)      = showVar v ++ " <- " ++ showVar v ++ " - 1"
showStatement (Noop v)     = showVar v ++ " <- " ++ showVar v
showStatement (Goto v lbl) = "IF " ++ showVar v ++ " != 0 GOTO " ++ showLabel lbl

showVar :: Variable -> String
showVar OutputVar    = "Y"
showVar (InputVar i) = "X" ++ show i
showVar (LocalVar i) = "Z" ++ show i

-- A1 is written as A, like in the example program.
showLabel :: Label -> String
showLabel (Label letter 1) = show letter
showLabel (Label letter k) = show letter ++ show k
