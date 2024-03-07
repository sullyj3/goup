import Lake
open Lake DSL

package «up-lean» where
  -- add package configuration options here

lean_lib «UpLean» where
  -- add library configuration options here

@[default_target]
lean_exe «up-lean» where
  root := `Main
