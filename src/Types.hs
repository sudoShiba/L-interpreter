module Types where

import Numeric.Natural (Natural)

data Variable
  = InputVar Natural
  | LocalVar Natural
  | OutputVar
  deriving (Show, Eq, Ord)

data LabelLetter = A | B | C | D | E
  deriving (Show, Eq, Ord)

data Label = Label LabelLetter Natural
  deriving (Show, Eq, Ord)

data Statement
  = Inc  Variable       -- V <- V + 1
  | Dec  Variable       -- V <- V - 1
  | Noop Variable       -- V <- V
  | Goto Variable Label -- IF V ≠ 0 GOTO L
  deriving (Show, Eq)

data Instruction
  = Unlabeled Statement
  | Labeled Label Statement
  deriving (Show, Eq)

type Program = [Instruction]

infix 4 :=
data Equation = Variable := Natural
  deriving (Show, Eq, Ord)

type State = [Equation]

type Snapshot = (Natural, State)

type Computation = [Snapshot]

