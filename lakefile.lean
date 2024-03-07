import Lake
open Lake DSL

package «goup» where
  -- add package configuration options here

lean_lib «Goup» where
  -- add library configuration options here

@[default_target]
lean_exe «goup» where
  root := `Main
