open System (FilePath)

partial def System.FilePath.allAncestors (path : FilePath) : List FilePath :=
  match path.parent with
  | some (FilePath.mk "") => [FilePath.mk "/"]
  | some parent => parent :: allAncestors parent
  | none => [] -- unreachable unless path = FilePath.mk ""

def prompt (p : String) : IO String := do
  IO.print p
  (← IO.getStdout).flush
  let stdin ← IO.getStdin
  let line ← stdin.getLine
  pure line.trimRight

def main (args : List String) : IO UInt32 := do
  -- collect ancestors
  let cwd ← IO.currentDir
  let ancestors : (List FilePath) := cwd.allAncestors

  let ((ancestor_number, temp_file_path) : Nat × FilePath) ← match args with
    | [] => throw <| IO.userError "Expected at least one argument: a temporary file supplied by the shell"
    | [temp_file_path]          => pure (← promptForAncestorNumber ancestors, FilePath.mk temp_file_path)
    | [temp_file_path, n_input] => pure (← parse_n n_input,                   FilePath.mk temp_file_path)
    | _ => throw $ IO.userError "Too many arguments"

  let n_0_indexed := ancestor_number - 1

  -- check it's in range. If it's greater than the number of ancestors, switch
  -- to the root directory, but print a warning
  let target_directory : FilePath ← if ok : n_0_indexed < ancestors.length then do
    pure <| ancestors[n_0_indexed]
  else do 
    IO.println "warning: current directory doesn't have that many ancestors! Switching to `/`"
    pure <| FilePath.mk "/"

  -- write it to temp file
  IO.FS.writeFile temp_file_path target_directory.toString
  pure 0

  where
    parse_n (n_input : String) : IO Nat := 
      match n_input with
      | "" => do
        IO.println "No input given. Staying in current directory."
        -- We return failure to signal to the shell script not to cd
        IO.Process.exit 1
      | _ => 
        match n_input.toNat? with
        | some n => pure n
        | none => do
          IO.println <| "Input must be a positive integer."
          IO.println "Staying in current directory."
          IO.Process.exit 1

    promptForAncestorNumber (ancestors : List FilePath) : IO Nat := do
      -- prompt for a 1-based index
      IO.println "Enter a number to navigate up to that directory"
      for ancestor in ancestors, i in [0:ancestors.length] do
        let i_1_indexed := i + 1
        IO.println s!"{i_1_indexed}: {ancestor}"
      let n_input : String ← prompt "> "
      parse_n n_input
