{
  pkgs,
  inputs,
  ...
}: {
  home.file = {
    ".XCompose" = {
      text = ''
        include "%L"

        # Math
        <Multi_key> <a> <p> <p> <r> : "≈"
        <Multi_key> <s> <q> : "√"
        <Multi_key> <f> <l> <l> : "⌊"
        <Multi_key> <f> <l> <r>: "⌋"
        <Multi_key> <c> <l> <l> : "⌈"
        <Multi_key> <c> <l> <r>: "⌉"
        <Multi_key> <plus> <minus> : "±"
        <Multi_key> <i> <n> <t> : "∫"
        <Multi_key> <d> <v> : "∂"
        <Multi_key> <period> <backslash> : "λ"
        <Multi_key> <i> <n> <f> : "∞"
        <Multi_key> <E> <M> : "∑"
        <Multi_key> <E> <(> : "∈"
        <Multi_key> <E> </> : "∉"

        # Logic
        <Multi_key> <T> <T> : "⊤"
        <Multi_key> <F> <F> : "⊥"
        <Multi_key> <exclam> <exclam> : "¬"
        <Multi_key> <a> <ampersand>: "∧"
        <Multi_key> <o> <v> <v> : "∨"
        <Multi_key> <x> <asciicircum> : "⊻"

        # Misc
        <Multi_key> <r> <e> <v> : "⇌"
      '';
    };
  };
}
