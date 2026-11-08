# L-Interpreter

An interpreter for Martin Davis's L language, written in Haskell and compiled to WebAssembly. It runs a program step by step in your browser and shows the state after every step.

Try it at <https://l.robertozunica.dev/>.

## The language

A program is a list of instructions, and each instruction can have a label:

| Statement          | Effect                               |
| ------------------ | ------------------------------------ |
| `V <- V + 1`       | Adds 1 to `V`                        |
| `V <- V - 1`       | Subtracts 1 from `V`, but stays at 0 |
| `V <- V`           | Does nothing                         |
| `IF V != 0 GOTO L` | Jumps to label `L` if `V` is not 0   |

- **Variables:** all `X1`, `X2`, ... are input variables, all `Z1`, `Z2`, ... are local variables and `Y` is the output variable.
- **Labels:** `A` to `E`, optionally numbered, written before a statement as `[A]` or `[B2]`.
- **Inputs:** enter them on the page, separated by commas. `3, 5` starts the program with `X1 = 3` and `X2 = 5`. Every other variable starts at 0.
- **Halting:** a program stops after its last instruction, or on a `GOTO` to a label that doesn't exist.

## Example

This program computes `Y = 2 * X1`:

```
[A] IF X1 != 0 GOTO B
    Z1 <- Z1 + 1
    IF Z1 != 0 GOTO E
[B] X1 <- X1 - 1
    Y <- Y + 1
    Y <- Y + 1
    Z1 <- Z1 + 1
    IF Z1 != 0 GOTO A
```

With input `3`, the trace starts and ends like this:

```
(1,[OutputVar := 0,InputVar 1 := 3,LocalVar 1 := 0])
...
(9,[OutputVar := 6,InputVar 1 := 0,LocalVar 1 := 4])
```

Each line shows the next instruction number and every variable. `OutputVar` is `Y`, `InputVar 1` is `X1` and `LocalVar 1` is `Z1`.

## Program numbers

Following Davis, every program `P` has a number `#(P)`, and every number is the number of exactly one program. On the page, **Encode program** shows the number of the program in the text box, and **Decode number** puts the program with a given number in the text box.

- Variables are numbered in the order `Y, X1, Z1, X2, Z2, ...` and labels in the order `A1, B1, C1, D1, E1, A2, ...`.
- An instruction gets the number `<a, <b, c>>`, with `<x, y> = 2^x * (2y + 1) - 1`.
- The program gets the number `[#(I1), ..., #(Ik)] - 1`: the product of the i-th prime to the power `#(Ii)`, minus 1.

These numbers grow very fast. Labels and variables with high indexes can give numbers that are too big to compute in the browser, and decoding a number with a large prime factor can take a very long time. A program that ends with an unlabeled `Y <- Y` loses that last instruction, because its number is 0 and adds a factor of 1. Davis excludes such programs for the same reason.

## Development

To work on the Haskell code, use GHC and cabal from the project root:

```sh
cabal build
cabal repl lib:l-interpreter
```

## Differences from Davis's L

In Davis's definition, variables hold arbitrarily large natural numbers and a program can run forever. This runner is finite: every run stops after a maximum number of steps, at most 2147483647, and all values have to fit in the browser's memory. A trace that stops at that maximum doesn't tell you whether the program would have halted.

## License

[MIT](LICENSE)
